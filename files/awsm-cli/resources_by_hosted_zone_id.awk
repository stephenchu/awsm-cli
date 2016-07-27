#! /usr/bin/awk -f

{
  results["hostedzone"] = results["hostedzone"] " " $1
}

END {
  for (item in results) {
    print item, results[item]
  }
}
