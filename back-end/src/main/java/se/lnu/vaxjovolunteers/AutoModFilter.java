package se.lnu.vaxjovolunteers;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import se.lnu.vaxjovolunteers.models.BadWordsItem;
import se.lnu.vaxjovolunteers.models.BadWordsList;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpResponse;

public class AutoModFilter {

  private final Logger log = LoggerFactory.getLogger(AutoModFilter.class);
  private HttpClient httpClient;
  private final String key = "tQar8ITwBlMddstJ3MGBda00yoSCJm7N";
  private final String badwordsUri = "https://api.apilayer.com/bad_words";
  private ObjectMapper objectMapper;
  private StringBuilder badWordsDetected;

  // build http client on AutoModFilter instantiation
  public AutoModFilter() {
    this.httpClient = HttpClient.newBuilder()
        .version(HttpClient.Version.HTTP_2)
        .build();
    this.objectMapper = new ObjectMapper();
  }

  // build the content of HTTP request
  private HttpRequest buildHTTPRequest(String contentToCheck) {
    HttpRequest request = HttpRequest.newBuilder()
        .POST(BodyPublishers.ofString(contentToCheck)) // body content
        .uri(URI.create(badwordsUri))
        .header("apikey", key)
        .build();
    return request;
  }

  // send request and receive response
  private HttpResponse<String> getHTTPResponse(HttpRequest request) throws IOException, InterruptedException {
    return this.httpClient.send(request, HttpResponse.BodyHandlers.ofString());
  }

  // check content that is passed
  public boolean checkPostContent(String contentToCheck) throws IOException, InterruptedException {
    String parsedContentToCheck = contentToCheck.replace("\n", " ");
    HttpResponse<String> response  = getHTTPResponse(buildHTTPRequest(parsedContentToCheck));
    log.debug("Received status code: {} with response {}", response.statusCode(), response.body());
    BadWordsList badwords = objectMapper.readValue(response.body(), BadWordsList.class);

    if(badwords.bad_words_total() > 0) {
      badWordsDetected = new StringBuilder();
      for(BadWordsItem i: badwords.bad_words_list()) {
        badWordsDetected.append(i.word() + "/");
      }
      return false;
    }
    return true;
  }

  // get detected bad words
  public String getbadWordsDetected() {
    return this.badWordsDetected.toString();
  }


}
