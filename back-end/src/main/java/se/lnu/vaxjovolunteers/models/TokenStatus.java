package se.lnu.vaxjovolunteers.models;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum TokenStatus {
    @JsonProperty("expired")
    EXPIRED,
    @JsonProperty("banned")
    BANNED,
    @JsonProperty("valid")
    VALID
}
