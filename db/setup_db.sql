create database re_svc_records character set utf8 collate utf8_unicode_ci ;
create user gen_api@localhost identified by 'ja89jh';
grant all on re_svc_records.* to gen_api@localhost;

CREATE TABLE clients(
  id INT NOT NULL AUTO_INCREMENT,
  created_at TIMESTAMP NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,

  name VARCHAR(30) NOT NULL,
  client_type INT NOT NULL,
  shared_secret VARCHAR(64) NOT NULL,

  PRIMARY KEY (id),
  KEY (name)
) ENGINE=InnoDB;    

CREATE TABLE request_log(
  id INT NOT NULL AUTO_INCREMENT,
  created_at TIMESTAMP NOT NULL DEFAULT 0,
  ottoken VARCHAR(64) NOT NULL,
  action VARCHAR(30) NOT NULL,
  controller VARCHAR(30),
  client VARCHAR(30) NOT NULL,
  PRIMARY KEY (id),
  KEY (ottoken)
) ENGINE=InnoDB;    

