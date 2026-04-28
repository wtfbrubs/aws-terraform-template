
resource "aws_acm_certificate" "cert" {
  domain_name = var.dominio
  validation_method = "DNS"

  subject_alternative_names = [
    format("*.%s", var.dominio)
  ]

  lifecycle {
    create_before_destroy = true
  }
}





data "aws_route53_zone" "zone" {
  name         = var.dominio
  private_zone = false
}


resource "aws_route53_record" "records" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
   # Skips the domain if it doesn't contain a wildcard
    if length(regexall("\\*\\..+", dvo.domain_name)) > 0
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.zone.zone_id
}




resource "aws_acm_certificate_validation" "cert_val" {
  certificate_arn         = aws_acm_certificate.cert.arn 
  validation_record_fqdns = [for record in aws_route53_record.records : record.fqdn]
}

