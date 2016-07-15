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

        switch(aws_service) {
          case "cloudformation":
            split(aws_resource_identifier, identifier_parts, "/")
            stack_constant = identifier_parts[1]
            stack_name     = identifier_parts[2]
            stack_additional_identifier = identifier_parts[3]

            results[region, aws_service] = results[region, aws_service] " " stack_name
        }
      } else {
        split($i, parts, /-/)
        aws_resource_type = parts[1]
        if (aws_resource_type ~ /^(aki|ami|ari|eipalloc|elb|subnet|i|vpc)$/) {
          aws_resource_identifier = $i
          if (length(results[region, aws_resource_type]) == 0)
            results[region, aws_resource_type] = results[region, aws_resource_type] aws_resource_identifier
          else
            results[region, aws_resource_type] = results[region, aws_resource_type] " " aws_resource_identifier
        }
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
