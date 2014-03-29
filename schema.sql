DROP TABLE IF EXISTS users, sites, user_sites, articles, opinions;

CREATE TABLE IF NOT EXISTS users(
  id int(11) NOT NULL AUTO_INCREMENT,
  name varchar(63) DEFAULT NULL,
  password varchar(63) DEFAULT NULL,
  email varchar(63) NOT NULL,
  img varchar(255) DEFAULT NULL,
  description varchar(255) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT 0,
  last_login TIMESTAMP DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY email (email)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS sites(
  id int(11) NOT NULL AUTO_INCREMENT,
  rss varchar(255) DEFAULT NULL,
  url varchar(255) NOT NULL,
  account varchar(255) DEFAULT NULL,
  token varchar(255) DEFAULT NULL,
  spec varchar(255) DEFAULT NULL,
  subscribed_at bigint DEFAULT 0,
  PRIMARY KEY (id)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS user_sites(
  user_id int(11) NOT NULL,
  site_id int(11) NOT NULL,
  title varchar(63) DEFAULT NULL,
  PRIMARY KEY (user_id,site_id)
  # FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  # FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS articles(
  id int(11) NOT NULL AUTO_INCREMENT,
  site_id int(11) DEFAULT NULL,
  url varchar(255) DEFAULT NULL,
  title varchar(63) DEFAULT NULL,
  description varchar(255) DEFAULT NULL,
  thumbnail varchar(255) DEFAULT NULL,
  category varchar(63) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT 0,
  added_at TIMESTAMP DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY url (url) 
  # FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE SET NULL
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS opinions(
  id int(11) NOT NULL AUTO_INCREMENT,
  user_id int(11) NOT NULL,
  article_id int(11) NOT NULL,
  orig_opinion_id int(11) DEFAULT NULL,
  contents varchar(255) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT 0,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY user_article (user_id, article_id),
  INDEX user_id (user_id),
  INDEX article_id (article_id)
  # FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  # FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
) DEFAULT CHARSET=utf8;


#INSERT INTO sites (rss, url) values ('http://blog.rss.naver.com/donodonsu.xml', 'http://www.naver.com');

