def tag_value(tag_name):
  . | values | map(
    select(.Key == tag_name)
  )[0].Value;

