#! /usr/bin/awk -f

function aws_resource_without_region(field_1) {
  return (field_1 == resource_type && region == "undefined")
}

function aws_resource_with_region(field_1, field_2) {
  return (field_1 == region && match(field_2, "^" resource_type "$"))
}

function skip_fields(starting_field_number) {
  return substr($0, index($0, $starting_field_number))
}

{
  if (aws_resource_without_region($1)) {
    print skip_fields(2)
  } else if (aws_resource_with_region($1, $2)) {
    print skip_fields(3)
  }
}
