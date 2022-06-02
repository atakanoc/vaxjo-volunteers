package se.lnu.vaxjovolunteers.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import io.javalin.http.Context;
import se.lnu.vaxjovolunteers.models.AppUserDB;
import se.lnu.vaxjovolunteers.models.GoogleUser;
import okhttp3.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import se.lnu.vaxjovolunteers.models.TokenStatus;

import javax.annotation.Nullable;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.UUID;

public class LoginController {
    private final Logger log = LoggerFactory.getLogger(LoginController.class);
    private DatabaseManager databaseManager;
    private OkHttpClient okHttpClient;
    String baseGoogleOAuthURL = "https://www.googleapis.com/oauth2/v1";

    public LoginController(DatabaseManager databaseManager, OkHttpClient okHttpClient) {
        this.databaseManager = databaseManager;
        this.okHttpClient = okHttpClient;
    }

    /**
     * Check if the provided credentials are validated by google.
     * Use only with login endpoint, access_token must exist in request.
     * @param accessToken access token of request.
     * @return The response to the request.
     */
    @Nullable
    public GoogleUser checkIfValidGoogle(String accessToken) {
        HttpUrl.Builder urlBuilder = HttpUrl.parse(baseGoogleOAuthURL + "/userinfo").newBuilder();
        urlBuilder.addQueryParameter("access_token", accessToken);

        String url = urlBuilder.build().toString();

        Request request = new Request.Builder().url(url).build();
        Call call = okHttpClient.newCall(request);
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            try (Response response = call.execute()) {
                if(response.body() == null) {
                    log.info("Response body is null");
                    return null;
                }
                return objectMapper.readValue(response.body().string(), GoogleUser.class);
            }
        } catch (IOException e) {
            log.error("Error while checking login", e);
            return null;
        }

    }

    /**
     * This is not cryptographically secure, but it's good enough for this demo
     *
     * @return a random string
     */
    public static String generateToken() {
        return UUID.randomUUID().toString();
    }

    @Nullable
    public boolean isValidLogin(String loginToken) {
        if(loginToken == null) {
            return false;
        }
        if(databaseManager.checkIfExistingUserFromLoginToken(loginToken)) {
            return !databaseManager.getExistingUserFromLoginToken(loginToken).isDisabled();
        } else {
            return false;
        }
    }

    public TokenStatus getTokenStatus(String loginToken) {
        if(!databaseManager.checkIfExistingUserFromLoginToken(loginToken)) {
                return TokenStatus.EXPIRED;
        }
        AppUserDB appUserDB = databaseManager.getExistingUserFromLoginToken(loginToken);

        if(appUserDB.isDisabled()) {
            return TokenStatus.BANNED;
        }

        return TokenStatus.VALID;
    }

    @Nullable
    public String getTokenFromRequest(Context ctx) {
        return ctx.header("authorization");
    }

    public String updateOrCreateUser(GoogleUser googleUser, String accessToken, String refreshToken, LocalDateTime expiryTime) {
        log.info("Updating or creating user for " + googleUser.googleID());
        if(databaseManager.checkIfExistingUser(googleUser.googleID())) {
            // user exists
            String token = generateToken();
            databaseManager.updateUser(googleUser, accessToken, refreshToken, expiryTime, token);
            return token;
        } else {
            // user does not exist, create new user
            String token = generateToken();
            databaseManager.createUser(googleUser, accessToken, refreshToken, expiryTime, token);
            return token;
        }
    }
}
