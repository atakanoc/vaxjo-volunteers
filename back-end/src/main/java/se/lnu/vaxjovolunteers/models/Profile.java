package se.lnu.vaxjovolunteers.models;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import org.jetbrains.annotations.Nullable;

@JsonSerialize
public record Profile(String googleID, String name, String profileImage,
                      @Nullable
                      String aboutMe,
                      boolean isDisabled,
                      boolean isModerator) {

  public static Profile fromAppUserDB(AppUserDB user){
    return new Profile(user.googleID(), user.name(), user.profileImage(), user.aboutMe(), user.isDisabled(), user.isModerator());
  }

}

