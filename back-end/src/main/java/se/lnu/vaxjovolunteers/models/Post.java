package se.lnu.vaxjovolunteers.models;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import se.lnu.vaxjovolunteers.jooq.enums.Category;
import se.lnu.vaxjovolunteers.jooq.enums.PostStatus;
import se.lnu.vaxjovolunteers.jooq.tables.records.PostsRecord;

import java.time.Instant;


@JsonSerialize
public record Post(
        Integer postID,
        String author_id,
        String author_name,
        String title,
        String description,
        Instant date,
        String category,
        String status,
        String modComment
) {
        public PostsRecord toDB(AppUserDB appUserDB, PostStatus postStatus, String modComment) {
                return new PostsRecord().setAuthorId(appUserDB.googleID()).setTitle(title).setDescription(description).setCategory(Category.lookupLiteral(category)).setStatus(postStatus).setModComment(modComment);
            }
}

