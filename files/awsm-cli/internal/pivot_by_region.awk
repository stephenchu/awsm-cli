#! /usr/bin/awk -f

{
  region = $1

  if (NF == 1) {
    results[region] = ""
  } else {
    for (i = 2; i <= NF; i++) {
      if ($i ~ /^arn:/) {
        split($i, arn_parts, /:/)
        aws_service             = arn_parts[3]
        aws_resource_identifier = arn_parts[6]

        switch (aws_service) {
          case "cloudformation":
            split(aws_resource_identifier, identifier_parts, "/")
            stack_constant = identifier_parts[1]
            stack_name     = identifier_parts[2]
            stack_additional_identifier = identifier_parts[3]

            results[region, aws_service] = results[region, aws_service] " " stack_name
        }
      } else {
        split($i, parts, /-/)
        if ($i ~ /^(us|eu|ap|sa|ca)-(north|south|)(east|central|west)-[[:digit:]][a-g]$/) {
          aws_resource_type = "az"
          aws_resource_identifier = $i
        } else if (parts[1] ~ /^(aki|ami|ari|eipalloc|elb|subnet|i|vpc)$/) {
          aws_resource_type = parts[1]
          aws_resource_identifier = $i
        } else {
          continue
        }

        if (length(results[region, aws_resource_type]) == 0)
          results[region, aws_resource_type] = aws_resource_identifier
        else
          if (index(results[region, aws_resource_type], aws_resource_identifier) == 0)
            results[region, aws_resource_type] = results[region, aws_resource_type] " " aws_resource_identifier
      }
    }
  }
}

END {
  for (item in results) {
    split(item, keys, SUBSEP)
    print keys[1], keys[2], results[item]
  }
}
