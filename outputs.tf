output "codecommit_repo_id" {
    value = "${aws_codecommit_repository.codecommit_site_repo.repository_id}"
}

output "codecommit_repo_arn" {
    value = "${aws_codecommit_repository.codecommit_site_repo.arn}"
}

output "codecommit_repo_clone_url_http" {
    value = "${aws_codecommit_repository.codecommit_site_repo.clone_url_http}"
}


output "codecommit_repo_clone_url_ssh" {
    value = "${aws_codecommit_repository.codecommit_site_repo.clone_url_ssh}"
}
