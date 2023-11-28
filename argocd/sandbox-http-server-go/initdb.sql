SET client_encoding = 'UTF8';

-- DROP TABLE access_log IF EXISTS;

CREATE TABLE access_log (
  id serial primary key,
  ip varchar(21) not null, -- <ipv4>:<port> (15 + 1 + 5 = 21 )
  url_path varchar(255) not null, -- url path
  access_ts timestamp not null
);

INSERT INTO access_log
  (ip, url_path, access_ts)
VALUES
  ('192.168.10.4', '/', NOW())
;
