DROP TABLE IF EXISTS users, categories, user_casts, papers, articles, collections, feedbacks;

CREATE TABLE IF NOT EXISTS users(
  id int(11) NOT NULL AUTO_INCREMENT,
  password varchar(63) NOT NULL,
  name varchar(63) NOT NULL,
  email varchar(63) NOT NULL,
  description varchar(255) DEFAULT NULL,
  created_at TIMESTAMP DEFAULT 0,
  last_login TIMESTAMP DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY email (email)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS categories(
  name varchar(63) NOT NULL,
  PRIMARY KEY (name)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS casts(
  id int(11) NOT NULL AUTO_INCREMENT,
  name varchar(63) NOT NULL,
  category varchar(63) DEFAULT NULL,
  description varchar(255) DEFAULT NULL,
  img varchar(255) DEFAULT NULL,
  PRIMARY KEY (id)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS user_casts(
  user_id int(11) NOT NULL,
  cast_id int(11) NOT NULL,
  PRIMARY KEY (user_id,cast_id)
  # FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  # FOREIGN KEY (cast_id) REFERENCES casts(id) ON DELETE CASCADE
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS papers(
  id int(11) NOT NULL AUTO_INCREMENT,
  cast_id int(11) NOT NULL,
  name varchar(63) NOT NULL,  # 1호, xx 특집 이런거..
  cover_img varchar(255) DEFAULT NULL,
  score int(11) DEFAULT 0,
  pub_at TIMESTAMP DEFAULT 0,
  PRIMARY KEY (id)
  # FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE SET NULL
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS articles(
  id int(11) NOT NULL AUTO_INCREMENT,
  paper_id int(11) NOT NULL,
  title varchar(127) NOT NULL,
  url varchar(255) NOT NULL,
  PRIMARY KEY (id)
  # FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  # FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS collections(
  user_id int(11) NOT NULL,
  cast_id int(11) NOT NULL,
  seq int(11) NOT NULL,           # for ordering
  PRIMARY KEY (user_id,cast_id)
) DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS feedbacks(
  paper_id int(11) NOT NULL,
  user_id int(11) NOT NULL,
  msg varchar(255) NOT NULL,
  score int(11) DEFAULT 0,
  at TIMESTAMP DEFAULT 0,
  PRIMARY KEY (paper_id,user_id)
) DEFAULT CHARSET=utf8;



#INSERT INTO sites (rss, url) values ('http://blog.rss.naver.com/donodonsu.xml', 'http://www.naver.com');

