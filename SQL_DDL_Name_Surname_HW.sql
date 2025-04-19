CREATE DATABASE Social_media;

-- Create schema
CREATE SCHEMA IF NOT EXISTS social_media;

-- UNIQUE for email and username so i can select id based on that
CREATE TABLE IF NOT EXISTS social_media.Users (
    User_id SERIAL PRIMARY KEY,
    Username text NOT NULL UNIQUE,
    Gender text CHECK (Gender IN ('male', 'female', 'non-binary', 'prefer-not-to-say')),
    Email text NOT NULL UNIQUE,
    Password text NOT NULL,
    Is_moderator boolean DEFAULT FALSE,
    Account_created_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Account_modified_time timestamp,
    User_description text
);

-- groups table
-- UNIQUE for group name for the same reason
CREATE TABLE IF NOT EXISTS social_media.Groups (
    Group_id SERIAL PRIMARY KEY,
    Group_name text NOT NULL UNIQUE,
    Group_description text,
    Created_by bigint NOT NULL,
    Group_created_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Created_by) REFERENCES social_media.Users(User_id)
);

-- group_Members table
CREATE TABLE IF NOT EXISTS social_media.Group_Members (
    Group_member_id SERIAL PRIMARY KEY,
    Group_id bigint NOT NULL,
    User_id bigint NOT NULL,
    Joined_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Is_group_admin boolean DEFAULT FALSE,
    FOREIGN KEY (Group_id) REFERENCES social_media.Groups(Group_id),
    FOREIGN KEY (User_id) REFERENCES social_media.Users(User_id),
    UNIQUE (Group_id, User_id)
);

-- posts table
CREATE TABLE IF NOT EXISTS social_media.Posts (
    Post_id SERIAL PRIMARY KEY,
    User_id bigint NOT NULL,
    Post_title text NOT NULL,
    Post_text text,
    Post_content text,
    Post_created_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Post_edited_time timestamp,
    Is_deleted boolean DEFAULT FALSE,
    Is_edited boolean DEFAULT FALSE,
    View_count bigint DEFAULT 0 CHECK (View_count >= 0),
    FOREIGN KEY (User_id) REFERENCES social_media.Users(User_id)
);

-- comments table
CREATE TABLE IF NOT EXISTS social_media.Comments (
    Comment_id SERIAL PRIMARY KEY,
    Post_id bigint NOT NULL,
    User_id bigint NOT NULL,
    Comment text NOT NULL,
    Comment_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Comment_edit_time timestamp,
    Is_edited boolean DEFAULT FALSE,
    Is_deleted boolean DEFAULT FALSE,
    Parent_Comment_id bigint,
    FOREIGN KEY (Post_id) REFERENCES social_media.Posts(Post_id),
    FOREIGN KEY (User_id) REFERENCES social_media.Users(User_id),
    FOREIGN KEY (Parent_Comment_id) REFERENCES social_media.Comments(Comment_id)
);

-- user_relationships table
CREATE TABLE IF NOT EXISTS social_media.User_relationships (
    Relationship_id SERIAL PRIMARY KEY,
    Followed_id bigint NOT NULL,
    Follower_id bigint NOT NULL,
    Muted boolean DEFAULT FALSE,
    FOREIGN KEY (Followed_id) REFERENCES social_media.Users(User_id),
    FOREIGN KEY (Follower_id) REFERENCES social_media.Users(User_id),
    UNIQUE (Followed_id, Follower_id)
);

-- notifications table
CREATE TABLE IF NOT EXISTS social_media.Notifications (
    Notification_id SERIAL PRIMARY KEY,
    User_id bigint NOT NULL,
    Notification_type text NOT NULL,
    Notification_content text NOT NULL,
    Is_read boolean DEFAULT FALSE,
    Notification_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (User_id) REFERENCES social_media.Users(User_id)
);

-- messages table
CREATE TABLE IF NOT EXISTS social_media.Messages (
    Message_id SERIAL PRIMARY KEY,
    Sender_id bigint NOT NULL,
    Received_id bigint NOT NULL,
    Message_content text NOT NULL,
    Is_read boolean DEFAULT FALSE,
    Message_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (Sender_id) REFERENCES social_media.Users(User_id),
    FOREIGN KEY (Received_id) REFERENCES social_media.Users(User_id)
);

-- user_post_data table
CREATE TABLE IF NOT EXISTS social_media.User_post_data (
    Post_id bigint NOT NULL,
    User_id bigint NOT NULL,
    Is_Like boolean DEFAULT FALSE,
    Is_shared boolean DEFAULT FALSE,
    PRIMARY KEY (Post_id, User_id),
    FOREIGN KEY (Post_id) REFERENCES social_media.Posts(Post_id),
    FOREIGN KEY (User_id) REFERENCES social_media.Users(User_id)
);

-- user_comment_data table
CREATE TABLE IF NOT EXISTS social_media.User_comment_data (
    Comment_id bigint NOT NULL,
    User_id bigint NOT NULL,
    Is_Like boolean DEFAULT FALSE,
    Is_dislike boolean DEFAULT FALSE,
    Is_shared boolean DEFAULT FALSE,
    PRIMARY KEY (Comment_id, User_id),
    FOREIGN KEY (Comment_id) REFERENCES social_media.Comments(Comment_id),
    FOREIGN KEY (User_id) REFERENCES social_media.Users(User_id)
);

--  insert users 
INSERT INTO social_media.Users (Username, Gender, Email, Password, Is_moderator, User_description)
VALUES 
    (UPPER('john_doe'), 'male', 'john@example.com', 'hashed123', FALSE, 'Software developer from NY'),
    (UPPER('dave_trix'), 'male', 'dave@example.com', 'hashed123', FALSE, 'Professional chef from China'),
    (UPPER('jane_smith'), 'female', 'jane@example.com', 'hashed456', TRUE, 'Community moderator')
ON CONFLICT (Username) DO NOTHING;

-- insert groups 
INSERT INTO social_media.Groups (Group_name, Group_description, Created_by)
SELECT UPPER('Tech Enthusiasts'), 'Discussion about latest technology', 
       (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe'))
UNION ALL
SELECT UPPER('Art Community'), 'Share and discuss artwork', 
       (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith'))
ON CONFLICT (Group_name) DO NOTHING;

-- insert group members 
INSERT INTO social_media.Group_Members (Group_id, User_id, Is_group_admin)
SELECT 
    (SELECT Group_id FROM social_media.Groups WHERE Group_name = UPPER('Tech Enthusiasts')), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe')), TRUE
UNION ALL
SELECT 
    (SELECT Group_id FROM social_media.Groups WHERE Group_name = UPPER('Art Community')), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), TRUE
ON CONFLICT (Group_id, User_id) DO NOTHING;

-- insert posts 
INSERT INTO social_media.Posts (User_id, Post_title, Post_text, Post_content, View_count)
SELECT (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe')), UPPER('New JavaScript Framework'), 'Exploring the latest framework...', 'content_url1', 150
UNION ALL
SELECT (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), UPPER('Community Guidelines'), 'Please read our updated rules...', 'content_url2', 320;

-- insert comments 
INSERT INTO social_media.Comments (Post_id, User_id, Comment)
SELECT 
    (SELECT Post_id FROM social_media.Posts WHERE Post_title = UPPER('New JavaScript Framework')), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), 'Great analysis!'
UNION ALL
SELECT 
    (SELECT Post_id FROM social_media.Posts WHERE Post_title = UPPER('Community Guidelines')), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe')), 'I DISLIKE THIS';

-- insert user relationships 
INSERT INTO social_media.User_relationships (Followed_id, Follower_id)
SELECT 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe')), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith'))
UNION ALL
SELECT 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe'))
ON CONFLICT (Followed_id, Follower_id) DO NOTHING;

-- insert notifications 
INSERT INTO social_media.Notifications (User_id, Notification_type, Notification_content)
SELECT 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe')), 
    'new_follower', 'jane_smith started following you'
UNION ALL
SELECT 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), 
    'new_follower', 'john_doe started following you';

-- insert user post data 
INSERT INTO social_media.User_post_data (Post_id, User_id, Is_Like, Is_shared)
SELECT 
    (SELECT Post_id FROM social_media.Posts WHERE Post_title = UPPER('Community Guidelines')), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), TRUE, FALSE
UNION ALL
SELECT 
    (SELECT Post_id FROM social_media.Posts WHERE Post_title = UPPER('New JavaScript Framework')), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), FALSE, TRUE
ON CONFLICT (Post_id, User_id) DO NOTHING;

-- insert user comment data 
INSERT INTO social_media.User_comment_data (Comment_id, User_id, Is_Like, Is_dislike, Is_shared)
SELECT 
    (SELECT Comment_id FROM social_media.Comments WHERE Comment = 'Great analysis!' AND User_id = (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith'))), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), TRUE, FALSE, FALSE
UNION ALL
SELECT 
    (SELECT Comment_id FROM social_media.Comments WHERE Comment = 'I DISLIKE THIS' AND User_id = (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe'))), 
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')), FALSE, FALSE, TRUE
ON CONFLICT (Comment_id, User_id) DO NOTHING;

-- insert sample data into Messages table
INSERT INTO social_media.Messages (Sender_id, Received_id, Message_content)
VALUES
    ((SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe')),
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')),
    'Hey Jane, check out my latest post!'),
    ((SELECT User_id FROM social_media.Users WHERE Username = UPPER('jane_smith')),
    (SELECT User_id FROM social_media.Users WHERE Username = UPPER('john_doe')),
    'Thanks for sharing, John! I''ll take a look.');

-- Add a not null 'record_ts' field to each table using ALTER TABLE statements, set the default value to current_date
ALTER TABLE social_media.Users ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.Groups ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.Group_Members ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.Posts ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.Comments ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.User_relationships ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.Notifications ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.Messages ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.User_post_data ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;
ALTER TABLE social_media.User_comment_data ADD COLUMN IF NOT EXISTS record_ts DATE NOT NULL DEFAULT CURRENT_DATE;