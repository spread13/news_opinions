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
);

CREATE TABLE IF NOT EXISTS sites(
  id int(11) NOT NULL AUTO_INCREMENT,
  rss varchar(255) NOT NULL,
  url varchar(255) DEFAULT NULL,  # if rss type..
  title varchar(63) DEFAULT NULL,
  rss_type int(1) DEFAULT 0,      # 0 url, 1 active rss, 2 inactive rss
  PRIMARY KEY (id),
  UNIQUE KEY rss (rss),
  INDEX rss_active (rss,rss_type)
);

CREATE TABLE IF NOT EXISTS user_sites(
  user_id int(11) NOT NULL,
  site_id int(11) NOT NULL,
  credentials varchar(255) DEFAULT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id,site_id),
  INDEX site_id (site_id)
  # FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  # FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS articles(
  id int(11) NOT NULL AUTO_INCREMENT,
  site_id int(11) DEFAULT NULL,
  url varchar(255) DEFAULT NULL,
  title varchar(63) DEFAULT NULL,
  description varchar(255) DEFAULT NULL,
  thumbnail varchar(255) DEFAULT NULL,
  category varchar(63) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT 0,
  PRIMARY KEY (id),
  INDEX site_id (site_id),
  INDEX category (category)
  # FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE SET NULL
);

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
  INDEX user_id (user_id),
  INDEX article_id (article_id)
  # FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  # FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
);


