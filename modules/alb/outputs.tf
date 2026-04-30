output "alb_arn" {
  value = aws_lb.alb.arn
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}


output "alb_listener80_arn" {
  value = aws_lb_listener.listener80.arn
}

output "alb_listener443_arn" {
  value = aws_lb_listener.listener443.arn
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

