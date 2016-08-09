#! /usr/bin/awk -f

{
  if ($1 ~ /^\/hostedzone\//) {
    results["hostedzone"] = results["hostedzone"] " " $1
  }
}

END {
  for (item in results) {
    print item, results[item]
  }
}
