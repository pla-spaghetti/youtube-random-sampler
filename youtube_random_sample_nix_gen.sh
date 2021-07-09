if [ "$#" -ne 1 ]; then
  echo usage: ./youtube_random_sample_nix_gen.sh len 
  exit 1
fi

check_words() {
  md5=($(md5sum words_alpha.txt))
  if [ "$md5" != "c2f8ff9e76cf7398cfbeaef28cddc411" ]; then
    echo fee fi fo fum, unexpected md5 sum...
    exit 1
  fi
}

download_words_if_missing() {
  if test -f "words_alpha.txt"; then
    echo surfing for content 
  else
    echo downloading words
    curl https://raw.githubusercontent.com/dwyl/english-words/master/words.txt > words_alpha.txt
    check_words
  fi
}

download_words_if_missing

SLICE_LEN=$1

random_word() {
  cat words_alpha.txt | shuf -n 1 | sed 's/[^a-z]*//g' 
}

search_yt() {
  youtube-dl "ytsearch:$1" --get-id
}

get_duration() {
  youtube-dl --get-duration "$1"
}

duration_to_secs() {
  MINS=$(echo $1 | cut -d: -f1)
  SECS=$(echo $1 | cut -d: -f2)
  echo $MINS*60 + $SECS | bc
}

get_full_url() {
  youtube-dl -f worst -g "https://www.youtube.com/watch?v=$1" | head -n 1
}

nixfile() {
  echo "{ pkgs ? import <nixpkgs> {} }:"
  echo "  with pkgs;"
  echo "   runCommand \"$4\" {"
  echo "      outputHash = \"0000000000000000000000000000000000000000000000000000\";"
  echo "      outputHashAlgo = \"sha256\";"
  echo "      buildInputs = [ ffmpeg ];"
  echo "    } ''"
  echo "      ffmpeg -loglevel panic -ss $1 -i \"$3\" -t $2 -vf scale=640:360,setsar=1:1,fps=30 -c:v libx264 \"\$out\"" 
  echo "      ''"
}

gen_nix_file() { 
  nixfile $1 $2 $3 $4 > $4.nix 
  
  HASH=$(nix-build $4.nix 2>&1 | grep got | cut -d: -f 3)
  echo HASH = $HASH
  sed -i "s/0000000000000000000000000000000000000000000000000000/$HASH/" $4.nix
  
  nix-build $4.nix
  if [ $? -eq 0 ]; then
    echo success building $4.nix 
  else
    echo failure building $4.nix 
    echo cleaning up...
    rm $4.nix 
  fi
}

gen_random_slice_nix() {
  DURATION=$(duration_to_secs $(get_duration $2))
  echo DURATION=$DURATION
  re='^[0-9]+$'
  if ! [[ $DURATION =~ $re ]] ; then
       echo "error: DURATION not a number" >&2; exit 1
  fi
  if [ $1 -gt $DURATION ] ; then
    echo $1 is greater than DURATION $DURATION; exit 1
  fi 
  END=$(shuf -i $1-$DURATION -n 1)
  re='^[0-9]+$'
  if ! [[ $END =~ $re ]] ; then
       echo "error: END not a number" >&2; exit 1
  fi 
  START=$(echo $END - $1 | bc)
  if ! [[ $START =~ $re ]] ; then
       echo "error: START not a number" >&2; exit 1
  fi 
  echo getting slice $START-$END
  gen_nix_file $START $1 $(get_full_url $2) $3
}

WORD1=$(random_word)
WORD2=$(random_word)
COMPOUND="$WORD1 $WORD2"
echo searching for \"$COMPOUND\"
VIDID=$(search_yt "$COMPOUND")
IDLEN=$(echo -n $VIDID | wc -m)
# all youtube video IDs have length 11
if [ $IDLEN -ne "11" ] ; then
  echo youtube search failed for terms: $COMPOUND 
  exit
fi
echo found $VIDID
SLICE_NAME=$VIDID-$WORD1-$WORD2.mp4
echo making nix expression $SLICE_NAME
gen_random_slice_nix $SLICE_LEN $VIDID $SLICE_NAME


