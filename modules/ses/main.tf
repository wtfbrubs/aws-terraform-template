resource "aws_ses_domain_identity" "example" {
  domain = "seu-dominio.com"
}

# resource "aws_ses_domain_identity_policy" "example" {
#   domain     = aws_ses_domain_identity.example.domain
#   policy     = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [{
#     "Effect": "Allow",
#     "Principal": {
#       "Service": "ses.amazonaws.com"
#     },
#     "Action": "SES:SendEmail",
#     "Resource": "arn:aws:ses:us-east-1:123456789012:identity/seu-dominio.com"
#   }]
# }
# POLICY
# }


# resource "aws_route53_record" "example_amazonses_verification_record" {
#   zone_id = aws_route53_zone.example.zone_id
#   name    = "_amazonses.${aws_ses_domain_identity.example.id}"
#   type    = "TXT"
#   ttl     = "600"
#   records = [aws_ses_domain_identity.example.verification_token]
# }

# resource "aws_ses_domain_identity_verification" "example_verification" {
#   domain = aws_ses_domain_identity.example.id

#   depends_on = [aws_route53_record.example_amazonses_verification_record]
# }

# resource "aws_ses_configuration_set" "example" {
#   name = "ConfigSet"
# }

# resource "aws_ses_domain_dkim" "example" {
#   domain = aws_ses_domain_identity.example.domain
# }

# resource "aws_route53_record" "example_amazonses_dkim_record" {
#   count   = 3
#   zone_id = "ABCDEFGHIJ123"
#   name    = "${aws_ses_domain_dkim.example.dkim_tokens[count.index]}._domainkey"
#   type    = "CNAME"
#   ttl     = "600"
#   records = ["${aws_ses_domain_dkim.example.dkim_tokens[count.index]}.dkim.amazonses.com"]
# }


# resource "aws_ses_event_destination" "cloudwatch" {
#   name                   = "event-destination-cloudwatch"
#   configuration_set_name = aws_ses_configuration_set.example.name
#   enabled                = true
#   matching_types         = ["bounce", "send"]

#   cloudwatch_destination {
#     default_value  = "default"
#     dimension_name = "dimension"
#     value_source   = "emailHeader"
#   }
# }