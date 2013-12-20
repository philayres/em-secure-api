create database re_svc_identities character set utf8 collate utf8_unicode_ci ;
create user gen_api_ids@localhost identified by 'ja89jh';
grant all on re_svc_identities.* to gen_api_ids@localhost;
connect re_svc_identities;

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

CREATE TABLE user_identities (
  id INT NOT NULL AUTO_INCREMENT,
  uid VARCHAR(32) NOT NULL, 
  user_id VARCHAR(64) NOT NULL,
  name_first VARCHAR(64) NOT NULL,
  name_last VARCHAR(64) NOT NULL,
  dept VARCHAR(64), 
  org VARCHAR(64), 
  city  VARCHAR(64) NOT NULL, 
  state  VARCHAR(64) NOT NULL,
  country  VARCHAR(10) NOT NULL,
  email VARCHAR(64) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT 0, 
  updated_at TIMESTAMP NOT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY (user_id)
) ENGINE=InnoDB;    

CREATE TABLE user_keys (
  id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  user_uid VARCHAR(32) NOT NULL,
  serial INT NOT NULL,  
  private_key TEXT,
  public_key TEXT,
  certificate TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT 0,
  active_until TIMESTAMP,
  PRIMARY KEY (id),
  FOREIGN KEY (user_id) 
        REFERENCES user_identities(id)        
        ON DELETE CASCADE,
  KEY (user_uid)
) ENGINE=InnoDB;

CREATE TABLE active_user_keys (
  user_key_id INT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT 0,
  FOREIGN KEY (user_key_id) 
        REFERENCES user_keys(id)
        ON DELETE CASCADE
) ENGINE=INNODB;

