{if ($1 == "SMALL") SM = $2
 if ($1 == "BIG") BG = $2
 if ($2 == "time(small)") SMT = $3
 if ($2 == "time(big)") BGT = $3}

END {print SM "\t" BG "\t" SMT "\t" BGT}
