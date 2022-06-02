package se.lnu.vaxjovolunteers.models;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import se.lnu.vaxjovolunteers.jooq.enums.Category;
import se.lnu.vaxjovolunteers.jooq.enums.PostStatus;
import se.lnu.vaxjovolunteers.jooq.tables.records.PostsRecord;

@JsonSerialize
public record UserPost(
        String title,
        String description,
        String category
) {

    public PostsRecord toDB(AppUserDB appUserDB, PostStatus postStatus, String modComment) {
        return new PostsRecord().setAuthorId(appUserDB.googleID()).setTitle(title).setDescription(description).setCategory(Category.lookupLiteral(category)).setStatus(postStatus).setModComment(modComment);
    }
}
