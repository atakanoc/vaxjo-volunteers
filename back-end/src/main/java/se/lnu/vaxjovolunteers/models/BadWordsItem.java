package se.lnu.vaxjovolunteers.models;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;


@JsonSerialize
public record BadWordsItem(
       String original,
       String word,
       Integer deviations,
       Integer info,
       Integer start,
       Integer end,
       Integer replacedLen

) {
}
