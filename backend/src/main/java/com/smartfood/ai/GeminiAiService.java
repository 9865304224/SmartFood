package com.smartfood.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartfood.model.FoodItem;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class GeminiAiService {

    @Value("${smartfood.ai.api-key:${GEMINI_API_KEY:${AI_API_KEY:}}}")
    private String apiKey;

    @Value("${smartfood.ai.gemini.model:gemini-1.5-flash}")
    private String geminiModel;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private final RestTemplate restTemplate = new RestTemplate();

    public boolean isConfigured() {
        return apiKey != null && !apiKey.isBlank() && !apiKey.equalsIgnoreCase("YOUR_GEMINI_API_KEY");
    }

    public RecommendationService.CustomerAiAssistantResponse askGeminiFoodAssistant(
            String userQuery,
            List<FoodItem> availableItems,
            String customerContext) {

        if (!isConfigured()) {
            log.info("Gemini API key not configured. Using deterministic fallback.");
            return null;
        }

        try {
            // Prepare compact menu summary for prompt context
            StringBuilder menuSummary = new StringBuilder();
            for (int i = 0; i < Math.min(availableItems.size(), 30); i++) {
                FoodItem item = availableItems.get(i);
                menuSummary.append(String.format("- ID: %s | %s (₹%.0f) [%s, %s, ⭐%.1f]\n",
                        item.getId(),
                        item.getName(),
                        item.getPrice() != null ? item.getPrice() : 0.0,
                        item.isVeg() ? "Veg" : "Non-Veg",
                        item.getCategory() != null ? item.getCategory() : "General",
                        item.getRating() != null ? item.getRating() : 4.5
                ));
            }

            String systemInstruction = """
                    You are the SmartFood AI Chef and Dining Concierge.
                    Help the customer find the best meals matching their cravings, diet, or budget.
                    
                    Available Menu Catalog:
                    """ + menuSummary + """
                    
                    Instructions:
                    1. Recommend 2 to 4 items from the available menu above that best fit the customer's request.
                    2. Provide an enthusiastic, appetizing reply (1-3 sentences).
                    3. Provide a practical foodie tip (e.g. beverage pairings, flavor balance, discount tip).
                    4. Output strictly valid JSON in this format:
                    {
                      "answer": "Your friendly chef response here...",
                      "aiTip": "Your foodie tip here...",
                      "recommendedItemIds": ["id1", "id2"],
                      "intent": "e.g. BIRYANI_CRAVING, BUDGET_MEAL, HEALTHY, DESSERT"
                    }
                    """;

            String prompt = systemInstruction + "\nCustomer Query: \"" + userQuery + "\"";

            String geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/" + geminiModel + ":generateContent?key=" + apiKey;

            Map<String, Object> requestBody = Map.of(
                    "contents", List.of(
                            Map.of("parts", List.of(Map.of("text", prompt)))
                    ),
                    "generationConfig", Map.of(
                            "temperature", 0.7,
                            "topP", 0.95,
                            "topK", 40
                    )
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            ResponseEntity<String> response = restTemplate.postForEntity(geminiUrl, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode candidates = root.path("candidates");
                if (candidates.isArray() && !candidates.isEmpty()) {
                    String rawText = candidates.get(0)
                            .path("content")
                            .path("parts")
                            .get(0)
                            .path("text")
                            .asText();

                    log.info("Gemini raw response: {}", rawText);

                    // Extract JSON from markdown fences if Gemini returned ```json ... ```
                    String cleanJson = rawText.trim();
                    if (cleanJson.contains("```json")) {
                        cleanJson = cleanJson.substring(cleanJson.indexOf("```json") + 7);
                        if (cleanJson.contains("```")) {
                            cleanJson = cleanJson.substring(0, cleanJson.indexOf("```"));
                        }
                    } else if (cleanJson.contains("```")) {
                        cleanJson = cleanJson.substring(cleanJson.indexOf("```") + 3);
                        if (cleanJson.contains("```")) {
                            cleanJson = cleanJson.substring(0, cleanJson.indexOf("```"));
                        }
                    }
                    cleanJson = cleanJson.trim();

                    try {
                        JsonNode jsonNode = objectMapper.readTree(cleanJson);
                        String answer = jsonNode.path("answer").asText("Here are delicious meals curated specially for you by SmartFood AI Chef!");
                        String aiTip = jsonNode.path("aiTip").asText("Pro-tip: Tap 'Add to Cart' to enjoy fresh fast delivery!");
                        String intent = jsonNode.path("intent").asText("MEAL_DISCOVERY");

                        List<String> matchedIds = new ArrayList<>();
                        JsonNode idsNode = jsonNode.path("recommendedItemIds");
                        if (idsNode.isArray()) {
                            for (JsonNode idElem : idsNode) {
                                matchedIds.add(idElem.asText());
                            }
                        }

                        List<FoodItem> matchedItems = availableItems.stream()
                                .filter(item -> matchedIds.contains(item.getId()) || rawText.toLowerCase().contains(item.getName().toLowerCase()))
                                .limit(5)
                                .toList();

                        if (matchedItems.isEmpty()) {
                            matchedItems = availableItems.stream().limit(4).toList();
                        }

                        return new RecommendationService.CustomerAiAssistantResponse(
                                userQuery,
                                answer,
                                intent,
                                matchedItems,
                                aiTip
                        );
                    } catch (Exception parseEx) {
                        log.warn("Failed to parse Gemini JSON output, using text fallback: {}", parseEx.getMessage());
                        return new RecommendationService.CustomerAiAssistantResponse(
                                userQuery,
                                cleanJson,
                                "GEMINI_AI",
                                availableItems.stream().limit(4).toList(),
                                "Pro-tip: Add extra sides or drinks to complete your meal."
                        );
                    }
                }
            }
        } catch (Exception ex) {
            log.error("Gemini API call failed: {}. Falling back to smart deterministic engine.", ex.getMessage());
        }

        return null;
    }

    public String generateGeminiResponse(String prompt) {
        if (!isConfigured()) {
            return null;
        }

        try {
            String geminiUrl = "https://generativelanguage.googleapis.com/v1beta/models/" + geminiModel + ":generateContent?key=" + apiKey;

            Map<String, Object> requestBody = Map.of(
                    "contents", List.of(
                            Map.of("parts", List.of(Map.of("text", prompt)))
                    )
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);
            ResponseEntity<String> response = restTemplate.postForEntity(geminiUrl, entity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode candidates = root.path("candidates");
                if (candidates.isArray() && !candidates.isEmpty()) {
                    return candidates.get(0)
                            .path("content")
                            .path("parts")
                            .get(0)
                            .path("text")
                            .asText();
                }
            }
        } catch (Exception ex) {
            log.error("Gemini generate response error: {}", ex.getMessage());
        }
        return null;
    }
}
