package se.lnu.vaxjovolunteers.models;

import org.jooq.Context;
import org.jooq.DSLContext;
import se.lnu.vaxjovolunteers.jooq.tables.Users;
import se.lnu.vaxjovolunteers.jooq.tables.records.UsersRecord;
import org.jetbrains.annotations.Nullable;

import java.time.LocalDateTime;

public record AppUserDB(String googleID, String name, String profileImage,
                        @Nullable
                        String aboutMe,
                        String accessToken,
                        String refreshToken,
                        boolean isDisabled,
                        boolean isModerator,
                        String loginToken,
                        LocalDateTime accessTokenExpiration) {

    public static AppUserDB fromDB(UsersRecord usersRecord) {
        return new AppUserDB(
                usersRecord.getGoogleId(),
                usersRecord.getName(),
                usersRecord.getProfileImage(),
                usersRecord.getAboutMe(),
                usersRecord.getAccessToken(),
                usersRecord.getAccessToken(),
                usersRecord.getIsDisabled(),
                usersRecord.getIsModerator(),
                usersRecord.getLoginToken(),
                usersRecord.getAccessTokenExpiry()
        );
    }

    public UsersRecord getDB(DSLContext dslContext) {
        return dslContext.selectOne().from(Users.USERS).where(Users.USERS.GOOGLE_ID.eq(this.googleID)).fetchOneInto(UsersRecord.class);
    }

}
