output "cert_validado"{
    value = aws_acm_certificate_validation.cert_val.certificate_arn
}

output "zone_id"{
    value = data.aws_route53_zone.zone.zone_id
}