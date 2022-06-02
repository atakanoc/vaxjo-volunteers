package se.lnu.vaxjovolunteers.controller;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import se.lnu.vaxjovolunteers.jooq.enums.Category;
import se.lnu.vaxjovolunteers.jooq.enums.PostStatus;
import se.lnu.vaxjovolunteers.jooq.tables.Bookmarks;
import se.lnu.vaxjovolunteers.jooq.tables.Posts;
import se.lnu.vaxjovolunteers.jooq.tables.Users;
import se.lnu.vaxjovolunteers.jooq.tables.records.BookmarksRecord;
import se.lnu.vaxjovolunteers.jooq.tables.records.PostsRecord;
import se.lnu.vaxjovolunteers.jooq.tables.records.UsersRecord;
import se.lnu.vaxjovolunteers.models.AppUserDB;
import se.lnu.vaxjovolunteers.models.DBSettingClass;
import se.lnu.vaxjovolunteers.models.GoogleUser;
import se.lnu.vaxjovolunteers.models.Post;

import org.jetbrains.annotations.Nullable;
import org.jooq.DSLContext;
import org.jooq.Record;
import org.jooq.Result;
import org.jooq.SQLDialect;
import org.jooq.impl.DSL;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class DatabaseManager {
  private final DBSettingClass dbSettingClass;
  private final HikariDataSource dataSource;
  final DSLContext dslContext;
  private final Logger log = LoggerFactory.getLogger(DatabaseManager.class);
  private final boolean createDummyPosts = false;

  /**
   * Constructor for production purposes
   *
   * @param dbSettingClass DBSettingClass object containing the database settings
   */
  public DatabaseManager(DBSettingClass dbSettingClass) {
    // this gets the DB setting record class
    this.dbSettingClass = dbSettingClass;
    dataSource = buildDataSource(dbSettingClass);
    // This gets the DSLContext object for joooq
    dslContext = DSL.using(dataSource, SQLDialect.POSTGRES);
    // sets the catalog to our vaxjo_volunteers or any other
    dslContext.setCatalog(dbSettingClass.database()).executeAsync();
    if (createDummyPosts) {
      generateFakePosts();
    }
  }

  public DSLContext getDslContext() {
    return dslContext;
  }

  private HikariDataSource buildDataSource(DBSettingClass dbSettingClass) {
    final HikariConfig hikariConfig = new HikariConfig();
    // host and port is taken from the DBSettingClass object including database
    hikariConfig.setJdbcUrl(dbSettingClass.getJDBCUrl());
    hikariConfig.setUsername(dbSettingClass.username());
    hikariConfig.setPassword(dbSettingClass.password());

    // JOOQ will close this so no need to try with resources
    return new HikariDataSource(hikariConfig);
  }

  public boolean checkIfExistingUser(String googleID) {
    return dslContext.fetchExists(dslContext.selectOne()
        .from(Users.USERS)
        .where(Users.USERS.GOOGLE_ID.eq(googleID)));
  }

  /**
   * Gets a user and casts it into AppUserDB.
   * Only use this method if you know user exists otherwise it will throw, check
   * with checkIfExistingUserFromLoginToken method first.
   *
   * @param loginToken token of user
   * @return AppUserDB object
   * @throws IllegalStateException If user does not exist.
   */
  public AppUserDB getExistingUserFromLoginToken(String loginToken) {
    UsersRecord userRecord = dslContext.selectFrom(Users.USERS)
        .where(Users.USERS.LOGIN_TOKEN.eq(loginToken))
        .fetchOne();
    if (userRecord == null) {
      throw new IllegalStateException("User not found");
    }
    return AppUserDB.fromDB(userRecord);
  }

  public UsersRecord getExistingUserFromLoginTokenDB(String loginToken) {
    UsersRecord userRecord = dslContext.selectFrom(Users.USERS)
        .where(Users.USERS.LOGIN_TOKEN.eq(loginToken))
        .fetchOne();
    if (userRecord == null) {
      throw new IllegalStateException("User not found");
    }
    return userRecord;
  }

  public boolean checkIfExistingUserFromLoginToken(String loginToken) {
    return dslContext.fetchExists(dslContext.selectOne()
        .from(Users.USERS)
        .where(Users.USERS.LOGIN_TOKEN.eq(loginToken)));
  }

  /**
   * Get user with existing google ID, if not found it will throw.
   *
   * @param googleID Google ID of the user
   * @return AppUserDB object
   * @throws IllegalArgumentException if user is not found
   */
  public AppUserDB getExistingUser(String googleID) {
    UsersRecord usersRecord = dslContext.selectFrom(Users.USERS).where(Users.USERS.GOOGLE_ID.eq(googleID))
        .fetchOneInto(UsersRecord.class);
    if (usersRecord == null) {
      throw new IllegalArgumentException("User with googleID " + googleID + " does not exist");
    }
    return AppUserDB.fromDB(usersRecord);
  }

  public void createUser(GoogleUser googleUser, String accessToken, String refreshToken, LocalDateTime expiryTime,
      String loginToken) {
    UsersRecord usersRecord = dslContext.newRecord(Users.USERS);
    usersRecord.setGoogleId(googleUser.googleID());
    usersRecord.setName(googleUser.name());
    usersRecord.setProfileImage(googleUser.picture());
    usersRecord.setAboutMe("No Description.");
    usersRecord.setAccessToken(accessToken);
    usersRecord.setRefreshToken(refreshToken);
    usersRecord.setIsDisabled(false);
    usersRecord.setIsModerator(false);
    usersRecord.setLoginToken(loginToken);
    usersRecord.setAccessTokenExpiry(expiryTime);
    usersRecord.insert();
  }

  /**
   * Updates existing user in the database.
   *
   * @param googleUser   GoogleUser object
   * @param accessToken  access token
   * @param refreshToken refresh token
   * @param expiryTime   time of expiry for access token
   */
  public void updateUser(GoogleUser googleUser, String accessToken, String refreshToken, LocalDateTime expiryTime,
      String loginToken) {
    UsersRecord usersRecord = dslContext.selectFrom(Users.USERS)
        .where(Users.USERS.GOOGLE_ID.eq(googleUser.googleID())).fetchOneInto(UsersRecord.class);

    if (usersRecord == null) {
      throw new IllegalArgumentException("User with googleID " + googleUser.googleID() + " does not exist");
    }

    usersRecord.setName(googleUser.name());
    usersRecord.setProfileImage(googleUser.picture());
    usersRecord.setAccessToken(accessToken);
    usersRecord.setRefreshToken(refreshToken);
    usersRecord.setAccessTokenExpiry(expiryTime);
    usersRecord.setLoginToken(loginToken);
    usersRecord.update();
  }

  public void updateUserAboutMe(GoogleUser googleUser, String aboutMe) {
    UsersRecord usersRecord = dslContext.selectFrom(Users.USERS)
        .where(Users.USERS.GOOGLE_ID.eq(googleUser.googleID())).fetchOneInto(UsersRecord.class);

    if (usersRecord == null) {
      throw new IllegalArgumentException("User with googleID " + googleUser.googleID() + " does not exist");
    }

    usersRecord.setName(googleUser.name());
    usersRecord.setProfileImage(googleUser.picture());
    usersRecord.setAboutMe(aboutMe);
  }

  public AppUserDB getUserToken(String loginToken) {
    UsersRecord usersRecord = dslContext.selectFrom(Users.USERS).where(Users.USERS.LOGIN_TOKEN.eq(loginToken))
        .fetchOneInto(UsersRecord.class);
    return AppUserDB.fromDB(usersRecord);
  }

  private Result<Record> getAllPosts() {
    // generateFakePosts(); // remove later
    // returns records ordered by the descending date
    return dslContext.select().from(Posts.POSTS).orderBy(Posts.POSTS.POSTED_AT.desc()).fetch();
  }

  private Result<Record> getVisiblePosts(String googleID) {
    return dslContext.select().from(Posts.POSTS).where(Posts.POSTS.STATUS.eq(PostStatus.Approved))
        .or(Posts.POSTS.AUTHOR_ID.eq(googleID)).orderBy(Posts.POSTS.POSTED_AT.desc()).fetch();
  }

  public List<Post> getFormatedPosts(boolean getOnlyVisible, String googleID) {
    ArrayList<Post> posts = new ArrayList<>();
    Result<Record> postsRecord = getOnlyVisible ? getVisiblePosts(googleID) : getAllPosts();
    for (Record postRecord : postsRecord) {
      posts.add(new Post(postRecord.get("post_id", Integer.class),
          postRecord.get("author_id", String.class),
          getUserName(postRecord.get("author_id", String.class)).get("name", String.class),
          postRecord.get("title", String.class),
          postRecord.get("description", String.class),
          postRecord.get("posted_at", Instant.class),
          postRecord.get("category", Category.class).getLiteral(),
          postRecord.get("status", PostStatus.class).getLiteral(),
          postRecord.get("mod_comment", String.class)));
    }
    return posts;
  }

  public Post getSinglePost(PostsRecord record) {
      return new Post(record.get("post_id", Integer.class),
              record.get("author_id", String.class),
              getUserName(record.get("author_id", String.class)).get("name", String.class),
              record.get("title", String.class),
              record.get("description", String.class),
              record.get("posted_at", Instant.class),
              record.get("category", Category.class).getLiteral(),
              record.get("status", PostStatus.class).getLiteral(),
              record.get("mod_comment", String.class));
  }


  // fetching the name of the user according to his author_id in order to display
  // in posts feed
  private @Nullable Record getUserName(String author_id) {
    return dslContext.select().from(Users.USERS).where(Users.USERS.GOOGLE_ID.eq(author_id)).fetchOne();
  }

  public void generateFakePosts() {
    Random random = new Random();
    for (Integer i = 2; i < 50; i++) {
      PostsRecord postsRecord = new PostsRecord().setAuthorId("222222")
          .setTitle("Title " + i)
          .setDescription("Description " + i)
          .setPostedAt(LocalDateTime.now(Clock.system(ZoneId.of("Europe/Stockholm"))))
          .setCategory(Category.values()[random.nextInt(Category.values().length)])
          .setStatus(PostStatus.Approved)
          .setModComment(" ");
      try {
        insertPost(postsRecord);
      } catch (Exception e) {
        log.error("Error inserting post: ", e);
      }

    }
  }

  /**
   * set one row in posts table
   */
  public void insertPost(PostsRecord PostRecord) {
    dslContext.insertInto(Posts.POSTS)
        .set(PostRecord)
        .execute();
  }

  public ArrayList<Long> getFavorites(String googleID) {
    Result<BookmarksRecord> results = dslContext.selectFrom(Bookmarks.BOOKMARKS)
        .where(Bookmarks.BOOKMARKS.GOOGLE_ID.eq(googleID)).fetch();
    ArrayList<Long> posts = new ArrayList<>();

    for (BookmarksRecord record : results) {
      posts.add(record.value2());
    }

    return posts;
  }

  public boolean addFavorite(String googleID, long postID) {
    Result<BookmarksRecord> results = dslContext.selectFrom(Bookmarks.BOOKMARKS)
        .where(Bookmarks.BOOKMARKS.GOOGLE_ID.eq(googleID)).and(Bookmarks.BOOKMARKS.POST_ID.eq(postID)).fetch();
    if (!results.isEmpty()) {
      return false; // already faved
    } else {
      BookmarksRecord record = dslContext.newRecord(Bookmarks.BOOKMARKS);
      record.setGoogleId(googleID);
      record.setPostId(postID);
      record.insert();

      return true;
    }
  }

  public boolean removeFavorite(String googleID, long postID) {
    Result<BookmarksRecord> results = dslContext.selectFrom(Bookmarks.BOOKMARKS)
        .where(Bookmarks.BOOKMARKS.GOOGLE_ID.eq(googleID)).and(Bookmarks.BOOKMARKS.POST_ID.eq(postID)).fetch();
    if (results.isEmpty()) {
      return false; // already not faved
    } else {
      BookmarksRecord record = dslContext.newRecord(Bookmarks.BOOKMARKS);
      record.setGoogleId(googleID);
      record.setPostId(postID);
      record.delete();

      return true;
    }
  }

  public boolean approvePost(long postID) {
    Result<PostsRecord> results = dslContext.selectFrom(Posts.POSTS).where(Posts.POSTS.POST_ID.eq(postID)).fetch();
    if (results.isNotEmpty()) {
      PostsRecord thePost = results.get(0);
      if (thePost.component7() != PostStatus.Approved) {
        thePost.setStatus(PostStatus.Approved);
        thePost.update();
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  public boolean pendingPost(long postID) {
    Result<PostsRecord> results = dslContext.selectFrom(Posts.POSTS).where(Posts.POSTS.POST_ID.eq(postID)).fetch();
    if (results.isNotEmpty()) {
      PostsRecord thePost = results.get(0);
      if (thePost.component7() != PostStatus.Pending) {
        thePost.setStatus(PostStatus.Pending);
        thePost.update();
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  public boolean hidePost(long postID) {
    Result<PostsRecord> results = dslContext.selectFrom(Posts.POSTS).where(Posts.POSTS.POST_ID.eq(postID)).fetch();
    if (results.isNotEmpty()) {
      PostsRecord thePost = results.get(0);
      if (thePost.component7() != PostStatus.Hidden) {
        thePost.setStatus(PostStatus.Hidden);
        thePost.update();
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  // delete post first from bookmarks and then from posts tables
  public boolean deletePost(long postID) {
    // delete from bookmarks table first
    dslContext.deleteFrom(Bookmarks.BOOKMARKS).where(Bookmarks.BOOKMARKS.POST_ID.eq(postID)).execute();
    // delete from posts table
    int record = dslContext.deleteFrom(Posts.POSTS).where(Posts.POSTS.POST_ID.eq(postID)).execute();
    if (record == 0) {
      return false; // nothing to delete
    }
    return true;

  }

  // get existing post from the posts table
  public PostsRecord getExistingPost(long postID) {
    PostsRecord post = dslContext.selectFrom(Posts.POSTS)
        .where(Posts.POSTS.POST_ID.eq(postID))
        .fetchOne();
    if (post == null) {
      throw new IllegalStateException("Post not found");
    }
    return post;
  }
}