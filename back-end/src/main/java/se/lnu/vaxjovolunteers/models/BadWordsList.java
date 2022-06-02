package se.lnu.vaxjovolunteers.models;

import java.util.List;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;


@JsonSerialize
public record BadWordsList(
       String content,
       Integer bad_words_total,
       List<BadWordsItem> bad_words_list,
       String censored_content

) {
}
