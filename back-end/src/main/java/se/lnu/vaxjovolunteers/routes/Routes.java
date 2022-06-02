package se.lnu.vaxjovolunteers.routes;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import io.javalin.Javalin;
import io.javalin.http.ContentType;
import io.javalin.http.Context;
import io.javalin.http.HttpCode;
import okhttp3.OkHttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import se.lnu.vaxjovolunteers.App;
import se.lnu.vaxjovolunteers.AutoModFilter;
import se.lnu.vaxjovolunteers.controller.DatabaseManager;
import se.lnu.vaxjovolunteers.controller.LoginController;
import se.lnu.vaxjovolunteers.jooq.enums.Category;
import se.lnu.vaxjovolunteers.jooq.enums.PostStatus;
import se.lnu.vaxjovolunteers.jooq.tables.Posts;
import se.lnu.vaxjovolunteers.jooq.tables.records.UsersRecord;
import se.lnu.vaxjovolunteers.models.*;
import se.lnu.vaxjovolunteers.jooq.tables.records.BookmarksRecord;
import se.lnu.vaxjovolunteers.jooq.tables.records.PostsRecord;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Routes {
  private int counter = 0;
  private final Logger log = LoggerFactory.getLogger(Routes.class);
  private final OkHttpClient okHttpClient = new OkHttpClient();
  private final LoginController loginController;
  private final DatabaseManager databaseManager;
  private final AutoModFilter autoModFilter;
  // The objectmapper below is the JSON serializer.
  // We register the time module and set WRITE_DATES as false, sgo we can have
  // dates in ISO format.
  private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule())
      .configure(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);

  public Routes(Javalin app, DatabaseManager databaseManager) {
    app.get("/", ctx -> ctx.result("Hello World"));

    this.databaseManager = databaseManager;
    this.loginController = new LoginController(databaseManager, okHttpClient);
    this.autoModFilter = new AutoModFilter();

    getPosts(app);
    getCategories(app);
    postSubmission(app);
    login(app);
    heartbeat(app);
    getProfile(app);
    postUserAboutMe(app);
    getFavorites(app);
    addFavorite(app);
    removeFavorite(app);
    approvePost(app);
    pendingPost(app);
    hidePost(app);
    deleteOwnPost(app);
    editOwnPost(app);
  }

  private void heartbeat(Javalin app) {
    app.post("/heartbeat", ctx -> {
      String loginToken = loginController.getTokenFromRequest(ctx);
      if (ctx.header(("authorization")) != null) {
        log.info("Login token: {}", loginToken);
        if (loginController.isValidLogin(loginToken)) {
          log.info("Login token was valid.");
          AppUserDB currentUser = databaseManager.getExistingUserFromLoginToken(loginToken);
          String json = objectMapper
              .writeValueAsString(new HeartbeatResponse(currentUser.googleID(), currentUser.isModerator()));
          ctx.contentType(ContentType.JSON);
          ctx.result(json);
          ctx.status(HttpCode.OK);
        } else {
          log.info("Login token was invalid.");
          returnResponseInvalid(loginToken, ctx);
        }
      } else {
        log.info("No login token was provided.");
        returnResponseInvalid(loginToken, ctx);
      }
    });
  }

  private void login(Javalin app) {
    app.post("/login", ctx -> {
      log.info(ctx.queryParamMap().toString());
      // We check that the request is valid and flutter client has sent us what we
      // need to retrieve data from google.
      if (ctx.queryParam("access_token") == null || ctx.queryParam("refresh_token") == null
          || ctx.queryParam("access_token_lifetime") == null) {
        ctx.status(HttpCode.BAD_REQUEST);
        log.info("Bad request received. No access token or refresh token");
        return;
      }

      // Function below used to handle google profile data and casting it into a
      // class.
      GoogleUser googleUser = loginController.checkIfValidGoogle(ctx.queryParam("access_token"));
      if (googleUser == null) {
        // If the user retrieved was null, due to revoked scopes or not return
        // unauthorized.
        ctx.status(HttpCode.UNAUTHORIZED);
      } else {
        // get all the tokens to save to database.
        String accessToken = ctx.queryParam("access_token");
        String refreshToken = ctx.queryParam("refresh_token");
        String accessTokenLifetime = ctx.queryParam("access_token_lifetime");

        // If access token was not sent or parsed invalid, should never error.
        if (accessTokenLifetime == null) {
          log.error("Access token lifetime is null");
          ctx.status(HttpCode.BAD_REQUEST);
          return;
        }

        // Parse the date into our format, local timezone.
        LocalDateTime expiryTime = LocalDateTime.from(LocalDateTime.parse(accessTokenLifetime,
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")));

        // Create or edit the user existing in database, if existing update names and
        // such, and do not touch about me.
        String loginToken = loginController.updateOrCreateUser(googleUser, accessToken, refreshToken,
            expiryTime);

        if (loginController.isValidLogin(loginToken)) {
          log.debug("Token is not valid after login, which means user is most likely banned.");
          // Returns a loginToken that we use to send back to user to be used in future
          // requests from flutter.
          Map<String, String> payload = new HashMap<>();
          payload.put("token", loginToken);
          String json = objectMapper.writeValueAsString(payload);
          ctx.contentType(ContentType.JSON);
          ctx.result(json);
          ctx.status(HttpCode.OK);
          // end of login

        } else {
          log.debug("It goes here.");
          returnResponseInvalid(loginToken, ctx);
        }
      }

      log.info("Login request received");
    });
  }

  private void getPosts(Javalin app) {

    app.get("/get-posts", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);
      if (loginController.isValidLogin(token)) {

        AppUserDB user = databaseManager.getExistingUserFromLoginToken(token);

        List<Post> partialSubmissions = databaseManager.getFormatedPosts(!user.isModerator(), user.googleID());
        String json = objectMapper.writeValueAsString(partialSubmissions);
        ctx.contentType(ContentType.JSON);
        ctx.result(json);
        log.debug("Posts Fetched");

      } else {
        returnResponseInvalid(token, ctx);
      }

    });
  }

  private void getCategories(Javalin app) {
    app.get("/get-category", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);
      if (loginController.isValidLogin(token)) {
        List<String> categories = new ArrayList<>();
        for (Category cat : Category.values()) {
          categories.add(cat.getLiteral());
        }
        String json = objectMapper.writeValueAsString(categories);
        ctx.contentType(ContentType.JSON);
        ctx.result(json);
        log.debug("Categories Fetched");
      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }

  // # TODO: Remove this when debugging profile is done
  private Integer hit = 0;

  private void getProfile(Javalin app) {

    app.get("/profile", ctx -> {
      hit += 1;
      // TODO remove
      log.debug("In total " + hit + " profile hits");
      String token = loginController.getTokenFromRequest(ctx);
      if (loginController.isValidLogin(token)) {
        AppUserDB user = databaseManager.getExistingUserFromLoginToken(token);
        // change to profile model
        String json = objectMapper.writeValueAsString(Profile.fromAppUserDB(user));
        ctx.contentType(ContentType.JSON);
        ctx.result(json);
        log.debug("User Fetched");
      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }

  // In case any database error - inform the user (needs to be implemented)
  private void postSubmission(Javalin app) {
    app.post("/post-submission", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);
      if (loginController.isValidLogin(token)) {
        // Get user, you can also cast into UserRecord by doing
        // appUserDB.getDB(databaseManager.getDslContext()).
        AppUserDB appUserDB = databaseManager.getExistingUserFromLoginToken(token);

        UserPost post = ctx.bodyAsClass(UserPost.class);
        String content = String.format("%s %s", post.title(), post.description());
        PostStatus status = PostStatus.Approved;
        String modComment = "OK";

        try {
          boolean goodContent = autoModFilter.checkPostContent(content);
          if (!goodContent) {
            status = PostStatus.Hidden;
            modComment = autoModFilter.getbadWordsDetected();
          }
          PostsRecord postsRecord = post.toDB(appUserDB, status, modComment);
          databaseManager.getDslContext().insertInto(Posts.POSTS).set(postsRecord).execute();
          if(goodContent) {
            ctx.status(HttpCode.OK);
          } else {
            ctx.status(HttpCode.BAD_REQUEST);
          }
        } catch (org.jooq.exception.DataAccessException e) {
          log.error("Error while inserting post into DB", e);
          ctx.status(HttpCode.INTERNAL_SERVER_ERROR);
        } catch (IOException | InterruptedException ex) {
          log.error("Error with the automated moderation filter", ex);
          ctx.status(HttpCode.INTERNAL_SERVER_ERROR);
        }
      } else {
        returnResponseInvalid(token, ctx);
      }
    });

  }

  private void getFavorites(Javalin app) {
    app.post("/get-favorites", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);

      if (loginController.isValidLogin(token)) {

        AppUserDB user = databaseManager.getExistingUserFromLoginToken(token);

        ArrayList<Long> posts = databaseManager.getFavorites(user.googleID());

        if (posts.isEmpty()) {
          log.debug("user has no favs - sending NO CONTENT"); // up for discussion how we communicate this.
          // we can just send the empty list and let the client figure out what that means
          ctx.status(HttpCode.NO_CONTENT);
        } else {
          String json = objectMapper.writeValueAsString(posts);
          ctx.contentType(ContentType.JSON);
          ctx.result(json);
          ctx.status(HttpCode.OK);
          log.debug("sent favorites");
        }
      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }

  private void postUserAboutMe(Javalin app) {
    app.post("/update-aboutMe", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);
      if (loginController.isValidLogin(token)) {
        // Get user, you can also cast into UserRecord by doing
        // appUserDB.getDB(databaseManager.getDslContext()).

        UsersRecord userRecord = databaseManager.getExistingUserFromLoginTokenDB(token);
        log.debug("User Record: " + userRecord.toString());
        Profile profile = ctx.bodyAsClass(Profile.class);
        try {
          log.debug("Setting About me to : " + profile.aboutMe());
          userRecord.setAboutMe(profile.aboutMe()).update();
          ctx.status(HttpCode.OK);
        } catch (org.jooq.exception.DataAccessException e) {
          log.error("Error while inserting post into DB", e);
          ctx.status(HttpCode.INTERNAL_SERVER_ERROR);
        }
      } else {
        returnResponseInvalid(token, ctx);
      }
    });

  }

  private void addFavorite(Javalin app) {
    app.post("/add-favorite", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);

      if (loginController.isValidLogin(token)) {

        AppUserDB user = databaseManager.getExistingUserFromLoginToken(token);
        Long postID = ctx.bodyAsClass(Long.class);

        boolean success = databaseManager.addFavorite(user.googleID(), postID);

        if (success) {
          ctx.status(HttpCode.OK);
        } else {
          ctx.status(HttpCode.PRECONDITION_FAILED);
        }

      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }

  private void removeFavorite(Javalin app) {
    app.post("/remove-favorite", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);

      if (loginController.isValidLogin(token)) {

        AppUserDB user = databaseManager.getExistingUserFromLoginToken(token);
        Long postID = ctx.bodyAsClass(Long.class);

        boolean success = databaseManager.removeFavorite(user.googleID(), postID);

        if (success) {
          ctx.status(HttpCode.OK);
        } else {
          ctx.status(HttpCode.PRECONDITION_FAILED);
        }

      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }

  private void approvePost(Javalin app) {
    app.post("/approve-post", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);

      if (loginController.isValidLogin(token)) {

        Long postID = ctx.bodyAsClass(Long.class);
        AppUserDB user = databaseManager.getExistingUserFromLoginToken(token);

        if (user.isModerator()) {
          boolean success = databaseManager.approvePost(postID);
          if (success) {
            ctx.status(HttpCode.OK);
          } else {
            ctx.status(HttpCode.PRECONDITION_FAILED);
          }
        } else {
          // ok same return code for not being a moderator as for post already approved
          // and post not existing but w/e
          ctx.status(HttpCode.PRECONDITION_FAILED);
        }

      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }

  // moderator setting post to pending (because want another moderator's
  // thoughts?)
  // OR user requesting manual moderation
  private void pendingPost(Javalin app) {
    app.post("/pending-post", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);

      if (loginController.isValidLogin(token)) {

        Long postID = ctx.bodyAsClass(Long.class);

        boolean success = databaseManager.pendingPost(postID);
        if (success) {
          ctx.status(HttpCode.OK);
        } else {
          ctx.status(HttpCode.PRECONDITION_FAILED);
        }

      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }

  // for both users and mods
  private void hidePost(Javalin app) {
    app.post("/hide-post", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);

      if (loginController.isValidLogin(token)) {

        Long postID = ctx.bodyAsClass(Long.class);

        boolean success = databaseManager.hidePost(postID);
        if (success) {
          ctx.status(HttpCode.OK);
        } else {
          ctx.status(HttpCode.PRECONDITION_FAILED);
        }

      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }

  private void returnResponseInvalid(String loginToken, Context context) {
    // finish writing the below method.

    if (loginToken == null) {
      context.status(HttpCode.BAD_REQUEST);
      return;
    }

    TokenStatus tokenStatus = loginController.getTokenStatus(loginToken);
    Map<String, TokenStatus> payload = new HashMap<>();
    payload.put("error", tokenStatus);
    try {
      String json = objectMapper.writeValueAsString(payload);
      context.status(HttpCode.UNAUTHORIZED);
      context.contentType(ContentType.JSON);
      context.result(json);
      log.debug("Returning: " + json);
    } catch (JsonProcessingException e) {
      context.status(HttpCode.INTERNAL_SERVER_ERROR);
      log.error("Error while parsing json", e);
    }
  }

  // deletes own post from all tables
  private void deleteOwnPost(Javalin app) {
    app.post("/delete-post", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);

      try {
        if (loginController.isValidLogin(token)) {
          Long postID = ctx.bodyAsClass(Long.class);
          if (databaseManager.deletePost(postID)) {
            ctx.status(HttpCode.OK);
            log.debug("Deleting post with ID : " + postID);
          } else {
            ctx.status(HttpCode.NOT_FOUND);
            log.debug("Post is not found, id : " + postID);
          }
        } else {
          returnResponseInvalid(token, ctx);
        }
      } catch (org.jooq.exception.DataAccessException e) {
        log.error("Error while deleting post from DB", e);
        ctx.status(HttpCode.INTERNAL_SERVER_ERROR);
      }
    });
  }

  // edit own post
  private void editOwnPost(Javalin app) {
    app.post("/edit-post", ctx -> {
      String token = loginController.getTokenFromRequest(ctx);
      if (loginController.isValidLogin(token)) {
        Post post = ctx.bodyAsClass(Post.class);
        String content = String.format("%s %s", post.title(), post.description());
        PostStatus status = PostStatus.Approved;
        String modComment = "OK";
        
        try {
          boolean goodContent = autoModFilter.checkPostContent(content);
          if (!goodContent) {
            status = PostStatus.Hidden;
            modComment = autoModFilter.getbadWordsDetected();
          }
          PostsRecord record = databaseManager.getExistingPost(post.postID());
          record.setCategory(Category.lookupLiteral(post.category())).setTitle(post.title())
              .setDescription(post.description()).setStatus(status).setModComment(modComment).update();
          if(goodContent) {
            ctx.status(HttpCode.OK);
          } else {
            ctx.status(HttpCode.BAD_REQUEST);
          }
          log.debug("Editing post with ID : " + post.postID());

          Post thePost = databaseManager.getSinglePost(record);
          String json = objectMapper.writeValueAsString(thePost);
          ctx.contentType(ContentType.JSON);
          ctx.result(json);

        } catch (IllegalStateException e) {
          ctx.status(HttpCode.NOT_FOUND);
          log.debug("Post is not found, id : " + post.postID());
        } catch (org.jooq.exception.DataAccessException e) {
          log.error("Error while inserting post edition into DB, postID " + post.postID());
          ctx.status(HttpCode.INTERNAL_SERVER_ERROR);
        } catch (IOException | InterruptedException ex) {
          log.error("Error with the automated moderation filter for postID " + post.postID());
          ctx.status(HttpCode.INTERNAL_SERVER_ERROR);
        }
      } else {
        returnResponseInvalid(token, ctx);
      }
    });
  }
}
