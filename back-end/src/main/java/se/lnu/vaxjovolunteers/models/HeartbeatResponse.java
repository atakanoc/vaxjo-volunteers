package se.lnu.vaxjovolunteers.models;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

@JsonSerialize
public record HeartbeatResponse(
        @JsonProperty("google_id")
        String googleID,
        @JsonProperty("moderator_status")
        boolean isModerator
) {
}
