#!/bin/bash
# =============================================================================
# collect_personal.sh - Enhanced & Robust Data Collection Script
# =============================================================================
# Features:
#   - Cached API calls (Genderize, Nationalize, Agify) to avoid rate limiting
#   - Improved name validation with weighted confidence
#   - Accurate Levenshtein distance for sports name suggestions
#   - Centralised current date retrieval
#   - Consistent gender checks for partner/spouse relationships
#   - Proper HIBP password breach detection
#   - More intuitive duplicate name warnings
#   - New: Favorite Sport validation using external sports_list.txt
#   - New: Type 'no' to skip any optional field instantly
# =============================================================================

set -o pipefail  # Preserve exit codes in pipelines

# ----------------------------- Colour Definitions ----------------------------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m'

OUTPUT_FILE="personal_data.txt"
> "$OUTPUT_FILE"

# ----------------------------- Global Cache Arrays ---------------------------
declare -A GENDER_CACHE
declare -A NATIONALITY_CACHE
declare -A AGE_CACHE
declare -A NAME_VALIDITY_CACHE

COLLECTED_NAMES=()
FIRST_NAME_GENDER=""
FIRST_NAME=""
CURRENT_DATE=""

# ----------------------------- Sports List from File -------------------------
SPORTS_LIST_FILE="sports_list.txt"
declare -a SPORTS_ARRAY=()

# ----------------------------- Helper Functions ------------------------------
get_input() {
    local prompt="$1"
    local input
    read -p "$(echo -e "$prompt")" input
    # Remove carriage returns and trim whitespace
    input="${input//$'\r'/}"
    input="$(echo -e "${input}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    echo "$input"
}

validate_name_chars() {
    local name="$1"
    [[ -z "$name" ]] && return 0
    # Allow letters, spaces, dots, hyphens, apostrophes
    if [[ "$name" =~ ^[A-Za-z\ .\'\-]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# ----------------------------- API Helpers -----------------------------------
call_api() {
    # Generic API caller with timeout and retry (1 retry)
    local url="$1"
    local response
    response=$(curl -s --max-time 5 --retry 1 "$url" 2>/dev/null)
    echo "$response"
}

get_current_date() {
    # Fetch once and cache
    if [[ -n "$CURRENT_DATE" ]]; then
        echo "$CURRENT_DATE"
        return 0
    fi
    local date_data=$(call_api "http://worldtimeapi.org/api/timezone/Asia/Dhaka")
    if [[ -n "$date_data" ]]; then
        local datetime=$(echo "$date_data" | grep -o '"datetime":"[^"]*"' | cut -d'"' -f4)
        if [[ -n "$datetime" ]]; then
            CURRENT_DATE="${datetime:0:10}"   # YYYY-MM-DD
            echo "$CURRENT_DATE"
            return 0
        fi
    fi
    # Fallback to system date
    CURRENT_DATE=$(date +%Y-%m-%d)
    echo "$CURRENT_DATE"
}

# ----------------------------- Name Validation APIs (Cached) -----------------
fetch_gender_data() {
    local name="$1"
    if [[ -n "${GENDER_CACHE[$name]}" ]]; then
        echo "${GENDER_CACHE[$name]}"
        return 0
    fi
    local data=$(call_api "https://api.genderize.io?name=$name")
    GENDER_CACHE[$name]="$data"
    echo "$data"
}

fetch_nationality_data() {
    local name="$1"
    if [[ -n "${NATIONALITY_CACHE[$name]}" ]]; then
        echo "${NATIONALITY_CACHE[$name]}"
        return 0
    fi
    local data=$(call_api "https://api.nationalize.io?name=$name")
    NATIONALITY_CACHE[$name]="$data"
    echo "$data"
}

fetch_age_data() {
    local name="$1"
    if [[ -n "${AGE_CACHE[$name]}" ]]; then
        echo "${AGE_CACHE[$name]}"
        return 0
    fi
    local data=$(call_api "https://api.agify.io?name=$name")
    AGE_CACHE[$name]="$data"
    echo "$data"
}

detect_gender() {
    local name="$1"
    [[ -z "$name" ]] && echo "unknown" && return 0

    # Use cached result if available
    if [[ -n "${GENDER_CACHE[$name]}" ]]; then
        local gender=$(echo "${GENDER_CACHE[$name]}" | grep -o '"gender":"[^"]*"' | cut -d'"' -f4)
        local prob=$(echo "${GENDER_CACHE[$name]}" | grep -o '"probability":[0-9.]*' | cut -d':' -f2)
    else
        local gender_data=$(fetch_gender_data "$name")
        local gender=$(echo "$gender_data" | grep -o '"gender":"[^"]*"' | cut -d'"' -f4)
        local prob=$(echo "$gender_data" | grep -o '"probability":[0-9.]*' | cut -d':' -f2)
    fi

    if [[ -n "$gender" && "$gender" != "null" ]] && (( $(echo "$prob > 0.6" | bc 2>/dev/null) )); then
        echo "$gender"
    else
        # Local fallback for common names if API uncertain
        local lower_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        case "$lower_name" in
            muhammad|ahmed|abdullah|omar|ali|hasan|hossain|rafiq|shafiq) echo "male" ;;
            fatima|aysha|khadija|sumaiya|nusrat|jannat|tahmina|rokeya) echo "female" ;;
            *) echo "unknown" ;;
        esac
    fi
}

validate_name_with_apis() {
    local name="$1"
    local field_desc="$2"
    [[ -z "$name" ]] && return 0

    echo -e "${YELLOW}   🔍 Verifying '$name' against global databases...${NC}"

    # Fetch all three datasets (cached)
    local gender_data=$(fetch_gender_data "$name")
    local nat_data=$(fetch_nationality_data "$name")
    local age_data=$(fetch_age_data "$name")

    local valid_score=0
    local total_checks=0

    # Genderize score (0-2 points)
    local gender=$(echo "$gender_data" | grep -o '"gender":"[^"]*"' | cut -d'"' -f4)
    local gender_prob=$(echo "$gender_data" | grep -o '"probability":[0-9.]*' | cut -d':' -f2)
    local gender_count=$(echo "$gender_data" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    if [[ -n "$gender" && "$gender" != "null" ]]; then
        total_checks=$((total_checks+2))
        if (( $(echo "$gender_prob > 0.7" | bc 2>/dev/null) )); then
            valid_score=$((valid_score+2))
            echo -e "${GREEN}   👤 Gender: $gender (high confidence, ${gender_prob})${NC}"
        elif (( $(echo "$gender_prob > 0.5" | bc 2>/dev/null) )); then
            valid_score=$((valid_score+1))
            echo -e "${YELLOW}   👤 Gender: $gender (moderate confidence, ${gender_prob})${NC}"
        else
            echo -e "${YELLOW}   👤 Gender: $gender (low confidence, ${gender_prob})${NC}"
        fi
    fi

    # Nationalize score (0-2 points)
    local country=$(echo "$nat_data" | grep -o '"country_id":"[^"]*"' | head -1 | cut -d'"' -f4)
    local nat_prob=$(echo "$nat_data" | grep -o '"probability":[0-9.]*' | head -1 | cut -d':' -f2)
    if [[ -n "$country" && "$country" != "null" ]]; then
        total_checks=$((total_checks+2))
        if (( $(echo "$nat_prob > 0.4" | bc 2>/dev/null) )); then
            valid_score=$((valid_score+2))
            echo -e "${GREEN}   🌍 Likely country: $country (${nat_prob})${NC}"
        else
            valid_score=$((valid_score+1))
            echo -e "${YELLOW}   🌍 Likely country: $country (low prob: ${nat_prob})${NC}"
        fi
    fi

    # Agify score (0-2 points)
    local age=$(echo "$age_data" | grep -o '"age":[0-9]*' | cut -d':' -f2)
    local age_count=$(echo "$age_data" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    if [[ -n "$age" && "$age" != "null" && $age_count -gt 100 ]]; then
        total_checks=$((total_checks+2))
        valid_score=$((valid_score+2))
        echo -e "${GREEN}   📅 Est. age: $age (samples: $age_count)${NC}"
    fi

    # Decision: require at least 60% of maximum possible score
    local threshold=$(( total_checks * 60 / 100 ))
    if [[ $total_checks -gt 0 && $valid_score -ge $threshold ]]; then
        echo -e "${GREEN}   ✓ '$name' is recognised as a human name.${NC}"
        return 0
    else
        echo -e "${RED}   ✗ '$name' could not be verified as a common human name.${NC}"
        return 1
    fi
}

# ----------------------------- Sports Validation (Improved) -----------------
levenshtein_distance() {
    local s1="$1"
    local s2="$2"
    local len1=${#s1}
    local len2=${#s2}
    local d=()
    for ((i=0; i<=len1; i++)); do d[i]=$i; done
    local tmp
    for ((j=1; j<=len2; j++)); do
        tmp=${d[0]}
        d[0]=$j
        for ((i=1; i<=len1; i++)); do
            local cost=0
            [[ "${s1:i-1:1}" != "${s2:j-1:1}" ]] && cost=1
            local del=$(( ${d[i]} + 1 ))
            local ins=$(( ${d[i-1]} + 1 ))
            local sub=$(( tmp + cost ))
            tmp=${d[i]}
            d[i]=$(( del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub) ))
        done
    done
    echo "${d[len1]}"
}

# Load sports list from external file
load_sports_list() {
    local sports_string='abseiling,acrobatics,acroski,aerobic gymnastics,afl,aggressive inline skating,aikido,air hockey,air racing,air soft,aizkolaritza,alpine skiing,american football,angling,aquathlon,archery,arena football,arm wrestling,artistic billiards,artistic cycling,artistic gymnastics,artistic pool,artistic roller skating,association football,athletics,australian rules football,austus,auto racing,autocross,axe throwing,backgammon,backpacking,backstroke,badminton,bagatelle,balance beam,balkline,ball badminton,ball hockey,ballet,bando,bandy,banger racing,bank pool,banzai skydiving,bar billiards,barefoot skiing,bare knuckle boxing,barrel racing,baseball,base jumping,basketball,basque pelota,basque traditional weightlifting,bat and trap,batman,baton twirling,battodo,beach basketball,beach handball,beach rugby,beach soccer,beach tennis,beach volleyball,beach wrestling,beeni,beer pong,bench press,biathlon,bicycle motocross,bicycle polo,bifins,big wave surfing,bikejoring,billiards,biribol,blackball,blind cricket,blind football,blitzball,boardercross,bobsleigh,bocce,boccia,bodyboarding,bodybuilding,bodyflight,bolas criollas,boomerang throwing,borden,bossaball,bottle pool,bouldering,boule lyonnaise,boules,bowling,bowlliards,bowls,boxing,brasilian jiu jitsu,breakdancing,breaststroke,bridge,british baseball,bronc riding,broomball,brutal,bubble football,bucketball,budo,bujinkan,bullfighting,bull riding,bumper pool,bungee jumping,bunnock,butterfly stroke,buzkashi,caber toss,cageball,caid,calcio fiorentino,calisthenics,camel racing,cammag,camogie,campdrafting,canadian football,canicross,canne de combat,canoeing,canoe marathon,canoe polo,canoe slalom,canoe sprint,canyoning,carom billiards,car racing,cart racing,casting,catch wrestling,cave diving,cestoball,chariot racing,charreada,checkers,cheerleading,cheese rolling,chess,chess boxing,chilean rodeo,chinlone,chito ryu,choi kwang do,chuckwagon racing,circle rules football,clay pigeon shooting,cliff diving,climbing,cluster ballooning,cnc,coasteering,cockfighting,coffin racing,combat sambo,combined driving,competitive eating,competitive juggling,cornhole,corkball,cowboy action shooting,cowboy polo,creeking,cribbage,cricket,croquet,cross country running,cross country skiing,crossfit,cue sports,curling,cushion caroms,cutting,cycle ball,cycle polo,cycle speedway,cycling,cyclo cross,czech handball,dai hee,dancesport,danish longball,darts,deadlift,decathlon,deep diving,deer hunting,demolition derby,desert racing,diamond pool,digor,dinghy racing,dirt track racing,disc dog,disc golf,disco polo,discus throw,diving,dodgeball,dog agility,dog racing,dog sledding,dog surfing,double disc court,downhill mountain biking,downhill skiing,drag boat racing,drag racing,dragon boat racing,dressage,drifting,drone racing,drumming,duathlon,dumog,dune bashing,durango boot,eight ball,ekiden,elephant polo,elephant racing,endurance racing,endurance riding,enduro,english billiards,epee fencing,equestrian,equestrian vaulting,escalade,esports,european handball,eventing,extreme ironing,f1,f2,f3,f4,falconry,farnarkeling,fast pitch softball,fastnet,fell running,fencing,ferret legging,field archery,field hockey,field lacrosse,field target,fierljeppen,figure skating,finswimming,firefighter combat challenge,fishing,fistball,five a side football,five pins,fives,flag football,flanker,flat track roller derby,floorball,floral games,flowboarding,flyboarding,fly fishing,flying disc,foam fighting,foil fencing,footbag,footgolf,foosball,footvolley,formula one,formula two,formula three,formula four,four ball,four square,fox hunting,free diving,free flying,free running,freeride skiing,freestyle bmx,freestyle footbag,freestyle football,freestyle motocross,freestyle skiing,freestyle snowboarding,freestyle swimming,freestyle wrestling,frisbee,frisian handball,frontenis,fujian white crane,fullbore target rifle,fussball,futebol de salao,futsal,gaelic football,gaelic handball,ga ga,game fishing,gateball,gatka,gauntlet,geocaching,gig racing,girevoy sport,gliding,glima,goalball,goalkeeping,goju ryu,golf,golf croquet,gomoku,go motorbike racing,gorodki,grand prix,grassboarding,grass skiing,grappling,gravity racing,greco roman wrestling,gridiron,gun fu,gungdo,guns,guts,gymkhana,gymnastics,haggis hurling,haidong gumdo,half marathon,halfpipe,hammer throw,handball,hang gliding,hapkido,hardball,hardcourt bike polo,hare coursing,harness racing,harpastum,hasai,hashing,headis,heptathlon,herding,hernes,high jump,highland games,hiking,hillclimbing,hockey,hojutsu,hooping,hooverball,hopak,hornussen,horseball,horse pulling,horse racing,horse riding,horseshoe pitching,hot air ballooning,human foosball,human tower,hunter jumper,hurdles,hurling,hwa rang do,hydroplane racing,hyrox,iaido,ice canoeing,ice climbing,ice cross downhill,ice dancing,ice fishing,ice hockey,ice racing,ice sailing,ice skating,ice speedway,ice stock sport,ice swimming,ice yachting,icosathlon,immersion,indiaca,indoor archery,indoor cricket,indoor cycling,indoor football,indoor hockey,indoor netball,indoor rowing,indoor soccer,indoor trial,indycar,inline hockey,inline skating,inline speed skating,intercrosse,international rules football,ironman,iska,jacquetball,jai alai,janggi,javelin throw,jazz dance,jeet kune do,jet skiing,jiu jitsu,joggling,jorkyball,jousting,judo,jugger,juggling,ju jitsu,jujutsu,kabaddi,kabuki,kajukenbo,kalaripayattu,kangoo jumps,karate,kart racing,kayaking,keg tossing,keirin,kemari,kempo,kendo,kenjutsu,kenpo,kettlebell lifting,kho kho,kickball,kickboxing,kick scooter,kila,kilikiti,kite boarding,kite buggy,kite fighting,kite flying,kite landboarding,kitesurfing,klovborg,knattleikr,kneeboarding,knife fighting,knife throwing,korfball,krabi krabong,krav maga,kronum,kudo,kung fu,kurash,kushti,kyudo,lacrosse,ladies gaelic football,land sailing,land windsurfing,laser tag,lasso,lawn bowling,lawn darts,lawn tennis,lelo burti,lethwei,letterboxing,lift,light contact,limalama,log rolling,lone wolf,longboarding,long distance running,long jump,longsword,luge,luta livre,lutte,maculele,madison,magic the gathering,mallakhamb,marathon,marching band,marn grook,martial arts,masters swimming,matkot,mauy thai,mcmap,medieval combat,medley swimming,mesoamerican ballgame,metallic silhouette,military pentathlon,miniature golf,minifootball,mixed climbing,mixed martial arts,modern arnis,modern pentathlon,mongolian wrestling,monster truck,moto ball,motocross,motorboat racing,motorcycle racing,motorcycle trials,motorsport,mountain biking,mountain boarding,mountain running,mountain unicycling,mountaineering,mud bogging,mud run,muay thai,muggle quidditch,mundial,mushing,naginata,nascar,netball,newcomb ball,nguni stick fighting,nine ball,ninjutsu,nintendo,nippers,nitro,no gi grappling,nordic combined,nordic skiing,nordic walking,novuss,obstacle course racing,ocean racing,octopush,offroad racing,oil wrestling,oina,okinawan kobudo,old english wrestling,one pocket,open water swimming,orienteering,othello,outrigger canoeing,paddleball,paddleboarding,paddle tennis,padle,paintball,pallone,pankration,panna,parachuting,paragliding,paralympic archery,paralympic athletics,paralympic swimming,paralympic table tennis,parasailing,parkour,patball,pato,pehlwani,pelota,pelota mixteca,penny farthing,pentathlon,pesapallo,petanque,pickleball,pigeon racing,pilates,ping pong,pioneerball,pipes,pitch and putt,planking,platform tennis,pochspiel,pocket billiards,pogo stick,poker,pole dancing,pole vault,polo,polocrosse,pond hockey,pontoon,pool,pop lacrosse,powerbocking,powerchair football,powerlifting,power soccer,practical shooting,pradal serey,prisoner ball,professional wrestling,psy,pugilism,pushball,push hands,puzzle,pyramid,qianli,quadrathlon,quidditch,quoits,racketball,racketlon,racquetball,racquet sports,racquet stringing,racquet,racquets,rafting,raid,rallycross,rally raid,rallying,rapid fire,rattlesnake roundup,real tennis,reining,revolver,rhythmic gymnastics,ribbon,ringball,ringing,ring tennis,rinkball,rink hockey,riverboarding,road bowling,road cycling,road racing,robot fighting,rock climbing,rocket league,rodeo,rogaining,roll ball,roller derby,roller disco,roller hockey,roller skating,roller soccer,roller speed skating,rope climbing,rope jumping,rope skipping,roping,rosin,roshambo,rotation,rounders,rowing,rugby fives,rugby league,rugby sevens,rugby tens,rugby union,running,russian pyramid,ryukyu kempo,sack race,sailing,sambo,samoa rules,sandboarding,sand volleyball,savate,scuba diving,sea kayaking,sepak takraw,seven ball,shidokan,shinty,shooting,shot put,showjumping,shuaijiao,shuffleboard,sikaran,silambam,silat,sipa,sitting volleyball,skateboarding,skeet shooting,skeleton,ski ballet,ski biking,ski boarding,ski bobbing,ski flying,skiing,ski jumping,ski mountaineering,ski orienteering,skittles,skwal,sky diving,skyrunning,slacklining,slalom,slamball,sledge hockey,slingshot,snooker,snorkeling,snowball fighting,snowbiking,snowblading,snowboarding,snowkiting,snowmobile racing,snowshoeing,soccer,softball,soft tennis,sombo,spearfishing,speedball,speed climbing,speed golf,speedminton,speed skating,speedway,spelunking,sphairee,spikeball,spinning,spiribol,splashball,sport acrobatics,sport aerobics,sport climbing,sport fishing,sport shooting,sports car racing,sprint car racing,sprinting,squash,squash tennis,ssireum,stacking,stage combat,stair climbing,steeplechase,steer wrestling,stickball,stick fighting,stoolball,straight pool,streetball,street hockey,street luge,street racing,street workout,stretching,strongman,subbuteo,sumo,superbike racing,supercross,super moto,surfboat rowing,surfing,survival,swimming,sword fighting,synchronized skating,synchronized swimming,systema,table football,table hockey,table tennis,taekkyeon,taekwondo,tag rugby,tai chi,tambo,tang soo do,target archery,target golf,target shooting,target sprint,tchoukball,team handball,team penning,team roping,te ano,tee ball,tejo,telemark skiing,ten ball,tennis,tennis polo,tent pegging,tetherball,tetrathlon,thang ta,three cushion,three day eventing,three gun,throwball,throwing,thumb wrestling,tidal bore rafting,time trial,tipp kick,toboggan,toe wrestling,tong il moo do,torball,touch football,touch rugby,tough mudder,tournament,tower running,track and field,track cycling,track racing,traditional archery,trail running,trampolining,trap shooting,trials,triathlon,tricking,trick skiing,trotting,truck racing,trugo,tug of war,tumbling,twirling,ultimate,ultimate frisbee,ultramarathon,underwater cycling,underwater football,underwater hockey,underwater ice hockey,underwater orienteering,underwater photography,underwater rugby,underwater target shooting,underwater wrestling,unicycle basketball,unicycle hockey,unicycling,unicycle trials,universal football,uppies and downies,urban exploration,v8 supercars,vajra mushti,vale tudo,varzesh e bastani,vaulting,vert skateboarding,vigoro,ving tsun,vintage racing,volleyball,volleyball variations,vovinam,wakeboarding,wakeskating,wakesurfing,walking,walking football,wallball,wallyball,warhammer,water aerobics,water basketball,water polo,water skiing,water volleyball,wave boarding,wave skiing,weightlifting,weight throw,wheelchair basketball,wheelchair curling,wheelchair fencing,wheelchair racing,wheelchair rugby,wheelchair tennis,whippet racing,wiffleball,windsurfing,wing chun,winter biathlon,winter pentathlon,winter swimming,wireball,wolf hunting,wood chopping,woodsman,workout,wrestling,wushu,xare,xiangqi,xingyiquan,yabusame,yachting,yahtzee,yak polo,yoga,yoga sports,yo yo,yukigassen,zipline,zorbing,zourkhaneh,zui quan'
    IFS=',' read -ra SPORTS_ARRAY <<< "$sports_string"
    for i in "${!SPORTS_ARRAY[@]}"; do
        SPORTS_ARRAY[$i]="$(echo "${SPORTS_ARRAY[$i]}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    done
    echo -e "${GREEN}   ✓ Loaded ${#SPORTS_ARRAY[@]} built-in sports.${NC}"
    return 0
}

# Validate favorite sport input against loaded list
validate_favorite_sport() {
    local input="$1"
    [[ -z "$input" ]] && return 0

    echo -e "${YELLOW}   🏃 Checking sports name: '$input'...${NC}"
    local lower_input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    local found=0
    local best_match=""
    local best_dist=999

    for sport in "${SPORTS_ARRAY[@]}"; do
        local lower_sport=$(echo "$sport" | tr '[:upper:]' '[:lower:]')
        if [[ "$lower_sport" == "$lower_input" ]]; then
            found=1
            break
        fi
        local dist=$(levenshtein_distance "$lower_input" "$lower_sport")
        if [[ $dist -lt $best_dist ]]; then
            best_dist=$dist
            best_match="$sport"
        fi
    done

    if [[ $found -eq 1 ]]; then
        echo -e "${GREEN}   ✓ Recognised sport.${NC}"
        return 0
    elif [[ -n "$best_match" && $best_dist -le 2 ]]; then
        echo -e "${YELLOW}   Did you mean '$best_match'? (distance $best_dist)${NC}"
        read -p "   Use this instead? (y/n): " use_match
        if [[ "$use_match" =~ ^[Yy]$ ]]; then
            # Update the variable in the caller scope (requires passing by reference or global)
            # We'll handle this by returning a suggestion and letting main handle assignment
            echo "$best_match"  # Output the suggested name
            return 2            # Special code for suggestion accepted
        else
            echo -e "${YELLOW}   Keeping original input.${NC}"
            return 0
        fi
    else
        echo -e "${YELLOW}   ⚠️  '$input' not found in sports database.${NC}"
        read -p "   Continue with this name? (y/n): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# ----------------------------- Pet Name Validation ---------------------------
validate_pet_name() {
    local name="$1"
    [[ -z "$name" ]] && return 0

    echo -e "${YELLOW}   🐾 Checking pet name '$name'...${NC}"
    local common_pets=("max" "bella" "lucy" "charlie" "rocky" "milo" "luna" "coco" "simba"
        "jack" "sadie" "bailey" "molly" "buddy" "maggie" "sophie" "chloe" "stella" "zeus"
        "loki" "thor" "rex" "tiger" "shadow" "smokey" "ginger" "patches" "mittens" "fluffy"
        "snowball" "tom" "jerry" "oscar" "felix" "garfield" "scooby" "pluto" "bruno")
    local lower_name=$(echo "$name" | tr '[:upper:]' '[:lower:]')

    for pet in "${common_pets[@]}"; do
        if [[ "$pet" == "$lower_name" ]]; then
            echo -e "${GREEN}   ✓ Common pet name.${NC}"
            return 0
        fi
    done

    # If not common pet, check if it's a human name (acceptable)
    local gender_data=$(fetch_gender_data "$name")
    local gender_count=$(echo "$gender_data" | grep -o '"count":[0-9]*' | cut -d':' -f2)
    if [[ -n "$gender_count" && $gender_count -gt 50 ]]; then
        echo -e "${GREEN}   ✓ Recognised human name, acceptable for a pet.${NC}"
        return 0
    fi

    echo -e "${YELLOW}   ⚠️  '$name' is not a common pet name.${NC}"
    read -p "   Continue with this pet name? (y/n): " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] && return 0 || return 1
}

# ----------------------------- Date Validation -------------------------------
validate_date_strict() {
    local day="$1"
    local month="$2"
    local year="$3"

    if [[ -z "$day" && -z "$month" && -z "$year" ]]; then
        return 0
    fi
    if [[ -z "$day" || -z "$month" || -z "$year" ]]; then
        echo -e "${RED}   ✗ All three parts (day, month, year) are required.${NC}"
        return 1
    fi

    # Basic format checks
    if ! [[ "$day" =~ ^[0-9]{1,2}$ && "$day" -ge 1 && "$day" -le 31 ]]; then
        echo -e "${RED}   ✗ Invalid day (1-31).${NC}"
        return 1
    fi
    if ! [[ "$month" =~ ^[0-9]{1,2}$ && "$month" -ge 1 && "$month" -le 12 ]]; then
        echo -e "${RED}   ✗ Invalid month (1-12).${NC}"
        return 1
    fi
    if ! [[ "$year" =~ ^[0-9]{4}$ ]]; then
        echo -e "${RED}   ✗ Year must be 4 digits.${NC}"
        return 1
    fi

    local current_date=$(get_current_date)
    local current_year=${current_date:0:4}
    if [[ $year -lt 1900 || $year -gt $current_year ]]; then
        echo -e "${RED}   ✗ Year must be between 1900 and $current_year.${NC}"
        return 1
    fi

    # Check if date is valid (handles leap years)
    if ! date -d "$year-$month-$day" &>/dev/null; then
        echo -e "${RED}   ✗ Date does not exist (e.g., 31st February).${NC}"
        return 1
    fi

    # Future date check
    local input_epoch=$(date -d "$year-$month-$day" +%s 2>/dev/null)
    local current_epoch=$(date -d "$current_date" +%s 2>/dev/null)
    if [[ -z "$input_epoch" || -z "$current_epoch" ]]; then
        echo -e "${RED}   ✗ Internal date conversion error.${NC}"
        return 1
    fi
    if [[ $input_epoch -gt $current_epoch ]]; then
        echo -e "${RED}   ✗ Date cannot be in the future.${NC}"
        return 1
    fi

    # Calculate approximate age
    local age=$(( (current_epoch - input_epoch) / 31536000 ))
    echo -e "${GREEN}   ✓ Valid date (approximate age: $age years)${NC}"
    return 0
}

# ----------------------------- Password Breach Check -------------------------
check_password_breach() {
    local pwd="$1"
    [[ -z "$pwd" ]] && return 0

    echo -e "${YELLOW}   🔐 Checking password against HIBP...${NC}"
    local hash=$(echo -n "$pwd" | sha1sum | cut -d' ' -f1 | tr '[:lower:]' '[:upper:]')
    local prefix=${hash:0:5}
    local suffix=${hash:5}

    local response=$(call_api "https://api.pwnedpasswords.com/range/$prefix")
    if [[ -z "$response" ]]; then
        echo -e "${YELLOW}   ⚠️  HIBP service unavailable. Proceeding.${NC}"
        return 0
    fi

    # Search for exact suffix match (case-insensitive)
    local found_line=$(echo "$response" | grep -i "^$suffix:")
    if [[ -n "$found_line" ]]; then
        local count=$(echo "$found_line" | cut -d':' -f2 | tr -d '\r')
        echo -e "${RED}   ⚠️  This password has appeared in $count data breaches!${NC}"
        read -p "   Use this password anyway? (y/n): " ans
        [[ "$ans" =~ ^[Yy]$ ]] && return 0 || return 1
    else
        echo -e "${GREEN}   ✓ Password not found in known breaches.${NC}"
        return 0
    fi
}

# ----------------------------- Name Consistency Warning ----------------------
check_duplicate_name_warning() {
    local new_name="$1"
    [[ -z "$new_name" ]] && return 0

    local lower_new=$(echo "$new_name" | tr '[:upper:]' '[:lower:]')
    for existing in "${COLLECTED_NAMES[@]}"; do
        local lower_ex=$(echo "$existing" | tr '[:upper:]' '[:lower:]')
        if [[ "$lower_new" == "$lower_ex" ]]; then
            echo -e "${YELLOW}   ⚠️  Note: '$new_name' is the same as a previously entered name.${NC}"
            return 0
        fi
    done
    return 0
}

# ----------------------------- Main Collection Process -----------------------
echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}       PERSONAL DATA COLLECTION (Enhanced Validator)${NC}"
echo -e "${WHITE}═══════════════════════════════════════════════════════════${NC}"

# 1. First Name (Required)
while true; do
    FIRST_NAME=$(get_input "${WHITE}1. First name: ${CYAN}")
    if [[ -z "$FIRST_NAME" ]]; then
        echo -e "${RED}   First name is required.${NC}"
        continue
    fi
    if ! validate_name_chars "$FIRST_NAME"; then
        echo -e "${RED}   Invalid characters. Only letters, spaces, dots, hyphens, apostrophes allowed.${NC}"
        continue
    fi
    if ! validate_name_with_apis "$FIRST_NAME" "First name"; then
        echo -e "${RED}   The name could not be verified as a common human name.${NC}"
        read -p "   Use it anyway? (y/n): " force
        if [[ ! "$force" =~ ^[Yy]$ ]]; then
            continue
        fi
    fi
    break
done
echo "$FIRST_NAME" >> "$OUTPUT_FILE"
COLLECTED_NAMES+=("$FIRST_NAME")
FIRST_NAME_GENDER=$(detect_gender "$FIRST_NAME")
echo -e "${GREEN}   ✓ First name accepted (gender: ${FIRST_NAME_GENDER}).${NC}"

# 2. Last Name (Optional) - modified to accept 'no' as skip
last_name=$(get_input "${WHITE}2. Last name (optional, type 'no' to skip): ${CYAN}")
if [[ "${last_name,,}" == "no" ]]; then
    last_name=""
    echo -e "${YELLOW}   ⏭️  Last name skipped.${NC}"
elif [[ -n "$last_name" ]]; then
    if ! validate_name_chars "$last_name"; then
        echo -e "${RED}   Invalid characters. Last name skipped.${NC}"
        last_name=""
    elif ! validate_name_with_apis "$last_name" "Last name"; then
        echo -e "${RED}   Could not verify as surname. Last name skipped.${NC}"
        last_name=""
    else
        check_duplicate_name_warning "$last_name"
        COLLECTED_NAMES+=("$last_name")
        echo -e "${GREEN}   ✓ Last name accepted.${NC}"
    fi
fi
echo "$last_name" >> "$OUTPUT_FILE"

# 3. Birth Date
echo -e "${WHITE}3. Birth date${NC}"
while true; do
    day=$(get_input "${WHITE}   Day (DD): ${CYAN}")
    month=$(get_input "${WHITE}   Month (MM): ${CYAN}")
    year=$(get_input "${WHITE}   Year (YYYY): ${CYAN}")
    if validate_date_strict "$day" "$month" "$year"; then
        echo "$day" >> "$OUTPUT_FILE"
        echo "$month" >> "$OUTPUT_FILE"
        echo "$year" >> "$OUTPUT_FILE"
        break
    fi
done

# 4. Mobile Numbers - modified to accept 'no' as skip
while true; do
    echo -e "${WHITE}4. Mobile numbers (comma separated, optional, type 'no' to skip):${NC}"
    echo -e "${CYAN}   Example: 01712345678,01876543210${NC}"
    mobile=$(get_input "${CYAN}   > ${NC}")
    if [[ -z "$mobile" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   Mobile numbers skipped.${NC}"
        break
    fi
    if [[ "${mobile,,}" == "no" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   ⏭️  Mobile numbers skipped.${NC}"
        break
    fi
    IFS=',' read -ra nums <<< "$mobile"
    valid=1
    for num in "${nums[@]}"; do
        num="${num// /}"
        if [[ ! "$num" =~ ^[0-9]{5,15}$ ]]; then
            echo -e "${RED}   Invalid: '$num' (5-15 digits).${NC}"
            valid=0
        fi
    done
    if [[ $valid -eq 1 ]]; then
        echo "$mobile" >> "$OUTPUT_FILE"
        echo -e "${GREEN}   ✓ Mobile number(s) accepted.${NC}"
        break
    fi
done

# 5. Partner Name (Girlfriend/Boyfriend) - modified to accept 'no' as skip
partner=""
partner_gender=""
echo -e "${WHITE}5. Girlfriend/Boyfriend name (optional, type 'no' to skip): ${CYAN}"
partner=$(get_input "")
if [[ "${partner,,}" == "no" ]]; then
    partner=""
    echo -e "${YELLOW}   ⏭️  Partner name skipped.${NC}"
elif [[ -n "$partner" ]]; then
    if ! validate_name_chars "$partner"; then
        echo -e "${RED}   Invalid characters. Partner name skipped.${NC}"
        partner=""
    elif ! validate_name_with_apis "$partner" "Partner name"; then
        echo -e "${RED}   Could not verify. Partner name skipped.${NC}"
        partner=""
    else
        partner_gender=$(detect_gender "$partner")
        # Gender must be opposite to first name
        if [[ "$FIRST_NAME_GENDER" != "unknown" && "$partner_gender" != "unknown" ]]; then
            if [[ "$FIRST_NAME_GENDER" == "$partner_gender" ]]; then
                echo -e "${RED}   ✗ Partner's gender ($partner_gender) matches your first name's gender.${NC}"
                echo -e "${RED}   Partner name rejected (must be opposite).${NC}"
                partner=""
            else
                echo -e "${GREEN}   ✓ Partner gender is opposite (${partner_gender}).${NC}"
                check_duplicate_name_warning "$partner"
                COLLECTED_NAMES+=("$partner")
                echo -e "${GREEN}   ✓ Partner name accepted.${NC}"
            fi
        else
            echo -e "${YELLOW}   ⚠️  Gender unknown, accepting partner name.${NC}"
            COLLECTED_NAMES+=("$partner")
        fi
    fi
fi
echo "$partner" >> "$OUTPUT_FILE"

# 6. Spouse Name - modified to accept 'no' as skip
spouse=""
spouse_gender=""
echo -e "${WHITE}6. Spouse name (optional, type 'no' to skip): ${CYAN}"
spouse=$(get_input "")
if [[ "${spouse,,}" == "no" ]]; then
    spouse=""
    echo -e "${YELLOW}   ⏭️  Spouse name skipped.${NC}"
elif [[ -n "$spouse" ]]; then
    if ! validate_name_chars "$spouse"; then
        echo -e "${RED}   Invalid characters. Spouse name skipped.${NC}"
        spouse=""
    elif ! validate_name_with_apis "$spouse" "Spouse name"; then
        echo -e "${RED}   Could not verify. Spouse name skipped.${NC}"
        spouse=""
    else
        spouse_gender=$(detect_gender "$spouse")
        # Must be opposite to first name
        if [[ "$FIRST_NAME_GENDER" != "unknown" && "$spouse_gender" != "unknown" ]]; then
            if [[ "$FIRST_NAME_GENDER" == "$spouse_gender" ]]; then
                echo -e "${RED}   ✗ Spouse gender matches your first name. Must be opposite.${NC}"
                spouse=""
            else
                echo -e "${GREEN}   ✓ Spouse gender is opposite (${spouse_gender}).${NC}"
                check_duplicate_name_warning "$spouse"
                COLLECTED_NAMES+=("$spouse")
                echo -e "${GREEN}   ✓ Spouse name accepted.${NC}"
            fi
        else
            echo -e "${YELLOW}   ⚠️  Gender unknown, accepting spouse name.${NC}"
            COLLECTED_NAMES+=("$spouse")
        fi
    fi
fi
echo "$spouse" >> "$OUTPUT_FILE"

# Additional logical check: if both partner and spouse exist, their genders should be opposite
if [[ -n "$partner" && -n "$spouse" && "$partner_gender" != "unknown" && "$spouse_gender" != "unknown" ]]; then
    if [[ "$partner_gender" == "$spouse_gender" ]]; then
        echo -e "${YELLOW}   ⚠️  Warning: Partner and spouse both have gender '$partner_gender'. This seems inconsistent.${NC}"
    fi
fi

# 7. Pet Name - modified to accept 'no' as skip
pet=$(get_input "${WHITE}7. Pet name (optional, type 'no' to skip): ${CYAN}")
if [[ "${pet,,}" == "no" ]]; then
    pet=""
    echo -e "${YELLOW}   ⏭️  Pet name skipped.${NC}"
elif [[ -n "$pet" ]]; then
    if ! validate_name_chars "$pet"; then
        echo -e "${RED}   Invalid characters. Pet name skipped.${NC}"
        pet=""
    elif ! validate_pet_name "$pet"; then
        echo -e "${RED}   Pet name rejected.${NC}"
        pet=""
    else
        echo -e "${GREEN}   ✓ Pet name accepted.${NC}"
    fi
fi
echo "$pet" >> "$OUTPUT_FILE"

# 8. City Name - modified to accept 'no' as skip
while true; do
    city=$(get_input "${WHITE}8. City name (optional, type 'no' to skip): ${CYAN}")
    if [[ -z "$city" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   City skipped.${NC}"
        break
    fi
    if [[ "${city,,}" == "no" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   ⏭️  City skipped.${NC}"
        break
    fi
    if ! validate_name_chars "$city"; then
        echo -e "${RED}   Invalid characters. Use letters, spaces, hyphens.${NC}"
        continue
    fi
    echo -e "${YELLOW}   🏙️  Verifying city...${NC}"
    encoded=$(echo "$city" | sed 's/ /%20/g')
    osm=$(call_api "https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=1")
    if echo "$osm" | grep -q '"display_name"'; then
        echo -e "${GREEN}   ✓ City found in OpenStreetMap.${NC}"
        echo "$city" >> "$OUTPUT_FILE"
        break
    else
        echo -e "${RED}   ✗ City not found. Please check spelling.${NC}"
    fi
done

# 9. Favorite Number - modified to accept 'no' as skip
while true; do
    fav=$(get_input "${WHITE}9. Favorite number (optional, type 'no' to skip): ${CYAN}")
    if [[ -z "$fav" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   Favorite number skipped.${NC}"
        break
    fi
    if [[ "${fav,,}" == "no" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   ⏭️  Favorite number skipped.${NC}"
        break
    fi
    if [[ "$fav" =~ ^-?[0-9]+$ ]]; then
        echo "$fav" >> "$OUTPUT_FILE"
        echo -e "${GREEN}   ✓ Favorite number accepted.${NC}"
        break
    else
        echo -e "${RED}   Invalid number. Use digits only.${NC}"
    fi
done

# 10. Old Passwords - modified to accept 'no' as skip
while true; do
    echo -e "${WHITE}10. Old passwords (comma separated, optional, type 'no' to skip):${NC}"
    old=$(get_input "${CYAN}   > ${NC}")
    if [[ -z "$old" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   Passwords skipped.${NC}"
        break
    fi
    if [[ "${old,,}" == "no" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   ⏭️  Passwords skipped.${NC}"
        break
    fi
    IFS=',' read -ra pwds <<< "$old"
    all_clean=1
    for p in "${pwds[@]}"; do
        p="${p// /}"
        if ! check_password_breach "$p"; then
            all_clean=0
        fi
    done
    if [[ $all_clean -eq 1 ]]; then
        echo "$old" >> "$OUTPUT_FILE"
        echo -e "${GREEN}   ✓ Passwords accepted.${NC}"
        break
    else
        echo -e "${RED}   Some passwords are breached. Please reconsider.${NC}"
    fi
done

# 11. Special Dates - modified to accept 'no' as skip
while true; do
    echo -e "${WHITE}11. Special dates (optional, DD-MM-YYYY comma separated, type 'no' to skip):${NC}"
    spec=$(get_input "${CYAN}   > ${NC}")
    if [[ -z "$spec" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   Special dates skipped.${NC}"
        break
    fi
    if [[ "${spec,,}" == "no" ]]; then
        echo "" >> "$OUTPUT_FILE"
        echo -e "${YELLOW}   ⏭️  Special dates skipped.${NC}"
        break
    fi
    IFS=',' read -ra dates <<< "$spec"
    all_valid=1
    current_date=$(get_current_date)
    current_epoch=$(date -d "$current_date" +%s)
    for dt in "${dates[@]}"; do
        dt="${dt// /}"
        if [[ ! "$dt" =~ ^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}$ ]]; then
            echo -e "${RED}   Invalid format: $dt (use DD-MM-YYYY).${NC}"
            all_valid=0
            break
        fi
        dd=$(echo "$dt" | cut -d'-' -f1)
        mm=$(echo "$dt" | cut -d'-' -f2)
        yy=$(echo "$dt" | cut -d'-' -f3)
        if [[ $dd -lt 1 || $dd -gt 31 || $mm -lt 1 || $mm -gt 12 || $yy -lt 1900 || $yy -gt ${current_date:0:4} ]]; then
            echo -e "${RED}   Invalid range: $dt.${NC}"
            all_valid=0
            break
        fi
        if ! date -d "$yy-$mm-$dd" &>/dev/null; then
            echo -e "${RED}   Date does not exist: $dt.${NC}"
            all_valid=0
            break
        fi
        input_epoch=$(date -d "$yy-$mm-$dd" +%s 2>/dev/null)
        if [[ $input_epoch -gt $current_epoch ]]; then
            echo -e "${RED}   Future date not allowed: $dt.${NC}"
            all_valid=0
            break
        fi
    done
    if [[ $all_valid -eq 1 ]]; then
        echo "$spec" >> "$OUTPUT_FILE"
        echo -e "${GREEN}   ✓ Special dates accepted.${NC}"
        break
    fi
done

# 12. Favorite Sport - modified to accept 'no' as skip
echo -e "${WHITE}12. Favorite sport (optional, type 'no' to skip): ${CYAN}"
favorite_sport=$(get_input "")
if [[ "${favorite_sport,,}" == "no" ]]; then
    favorite_sport=""
    echo -e "${YELLOW}   ⏭️  Favorite sport skipped.${NC}"
elif [[ -n "$favorite_sport" ]]; then
    if ! load_sports_list; then
        echo -e "${YELLOW}   ⚠️  Sports list file missing. Accepting input as is.${NC}"
    else
        # Call validation function and handle suggestion
        suggestion=$(validate_favorite_sport "$favorite_sport")
        ret_code=$?
        if [[ $ret_code -eq 2 ]]; then
            # Suggestion accepted
            favorite_sport="$suggestion"
            echo -e "${GREEN}   ✓ Using '$favorite_sport' as favorite sport.${NC}"
        elif [[ $ret_code -eq 0 ]]; then
            # Valid or user chose to keep original
            :
        else
            # Validation failed and user rejected
            favorite_sport=""
            echo -e "${RED}   Favorite sport rejected.${NC}"
        fi
    fi
    if [[ -n "$favorite_sport" ]]; then
        echo "$favorite_sport" >> "$OUTPUT_FILE"
        echo -e "${GREEN}   ✓ Favorite sport accepted.${NC}"
    else
        echo "" >> "$OUTPUT_FILE"
    fi
else
    echo "" >> "$OUTPUT_FILE"
    echo -e "${YELLOW}   Favorite sport skipped.${NC}"
fi

# ----------------------------- Summary ----------------------------------------
echo ""
echo -e "${GREEN}✓ Data collection complete. Saved to ${OUTPUT_FILE}${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}Preview of collected data:${NC}"
head -n 12 "$OUTPUT_FILE" | while read line; do
    [[ -n "$line" ]] && echo -e "${BLUE}  •${NC} $line"
done
echo ""

exit 0