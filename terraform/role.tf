resource "aws_iam_role" "demo5-jenkins" {
  name               = "${var.main_name}-jenkins"
  assume_role_policy = "${file("policy-aws/assumerolepolicy.json")}"
}

resource "aws_iam_policy" "policy" {
  name        = "${var.main_name}-jenkins-policy"
  description = "${var.main_name}-jenkins-policy"
  policy = "${file("policy-aws/demo5.json")}"
}

resource "aws_iam_policy_attachment" "attach" {
  name       = "attachment"
  roles      = ["${aws_iam_role.demo5-jenkins.name}"]
  policy_arn = "${aws_iam_policy.policy.arn}"
}

resource "aws_iam_instance_profile" "profile" {
  name  = "${var.main_name}-profile"
  role = "${aws_iam_role.demo5-jenkins.name}"
}
