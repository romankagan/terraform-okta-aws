resource "aws_iam_saml_provider" "okta_saml_provider" {
  name                   = "${var.idp_name}"
  saml_metadata_document = "${var.idp_metadata}"
}

locals {
  okta_assume_role_stanza = <<EOF
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "${aws_iam_saml_provider.okta_saml_provider.arn}"
  },
  "Action": "sts:AssumeRoleWithSAML",
  "Condition": {
    "StringEquals": {
      "SAML:aud": "https://signin.aws.amazon.com/saml"
    }
  }
}
EOF
}

data "aws_iam_policy_document" "okta_roles_lister_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["${var.master_accounts}"]
    }
  }
}

resource "aws_iam_role" "okta_roles_lister" {
  // This is a pre-defined/reserved name for Okta setup
  // See: https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-Amazon-Web-Service#B-step4
  name               = "Okta-Idp-cross-account-role"
  assume_role_policy = "${data.aws_iam_policy_document.okta_roles_lister_assume_policy.json}"
}

resource "aws_iam_role_policy" "okta_iam_read_only" {
  name   = "Okta-Idp-cross-account-role-policy"
  role   = "${aws_iam_role.okta_roles_lister.id}"
  policy = <<-EOF
{
      "Version": "2012-10-17",
      "Statement": [
          {
            "Effect": "Allow",
            "Action": [
                "iam:ListRoles",
                "iam:ListAccountAliases"
            ],
            "Resource": "*"
        }
    ]
}
  EOF
}