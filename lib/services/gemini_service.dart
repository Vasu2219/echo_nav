import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';

class GeminiService {
  final String apiKey;
  final String modelName;
  final double temperature;
  final int topK;
  final double topP;
  final int maxOutputTokens;
  final String systemInstruction;
  
  GeminiService({
    required this.apiKey,
    this.modelName = 'gemini-1.5-flash',
    this.temperature = 1.0,
    this.topK = 64,
    this.topP = 0.95,
    this.maxOutputTokens = 8192,
    this.systemInstruction = '',
  });
  
  // Navigation model - for analyzing surroundings and providing navigation guidance
  static GeminiService createNavigationModel(String apiKey) {
    return GeminiService(
      apiKey: apiKey,
      temperature: 1.0,
      systemInstruction: '''
Purpose: You're an advanced navigation assistant for visually impaired individuals. Your main task is to analyze camera frames, identify obstacles, and provide clear audio guidance.

Important Instructions:
1. Keep responses to 3-4 short sentences maximum
2. Describe specific objects with their colors, positions, and sizes (e.g., "blue car ahead", "metal pole to your right")
3. Always mention if the user is on a sidewalk, road, or other terrain
4. Prioritize safety warnings about obstacles, traffic, and hazards
5. Provide specific directions (e.g., "turn right", "stop", "proceed slowly")
6. For navigation, focus on path conditions, crosswalks, and landmarks
7. For urban environments, mention buildings, stores, and street names when visible
8. In indoor environments, describe room layouts, furniture, and doorways
9. Always maintain awareness of the real-time GPS directions when provided
10. Use the distance information to provide context about how far objects are

Never mention technical limitations or image quality issues. Focus only on what the user needs to navigate safely.
''',
    );
  }
  
  // Reading model - for text reading
  static GeminiService createReadingModel(String apiKey) {
    return GeminiService(
      apiKey: apiKey,
      temperature: 0.2,
      systemInstruction: '''
Purpose: You assist blind users by reading text from images.

Instructions:
1. First, describe the type of text (sign, book page, document, etc.)
2. Then read ALL text visible in the image accurately, in a logical reading order
3. For signs, start with the largest/main text, then smaller details
4. For documents, follow normal reading order (top to bottom, left to right)
5. Include important formatting or visual elements (bullet points, tables, etc.)
6. If text appears cut off, mention this
7. For mathematical content, describe equations clearly
8. For charts or diagrams with text, describe both the text and what the visual represents

Keep your introduction brief and focus on delivering the text content clearly and completely.
''',
    );
  }
  
  // Assistant model - for conversation
  static GeminiService createAssistantModel(String apiKey) {
    return GeminiService(
      apiKey: apiKey,
      temperature: 1.5,
      systemInstruction: '''
Purpose: You assist blind users by answering questions based on their surroundings and navigation needs.

Instructions:
1. When given environment information, use it to provide relevant guidance
2. Answer questions directly and concisely
3. For navigation questions, provide clear directional guidance
4. For object identification questions, be specific about colors, materials, and positions
5. For location questions, reference landmarks and street names when available
6. Use environmental context to provide the most helpful answers
7. When uncertain, admit limitations rather than guessing
8. Keep responses brief and optimized for text-to-speech
9. Focus on practical information rather than technical details
10. Prioritize safety-related information in all responses
''',
    );
  }
  
  // Process navigation frame with image
  Future<String> processNavigationFrame(
    List<int> imageBytes,
    {NavigationContext? navigationContext}
  ) async {
    try {
      debugPrint('Processing navigation frame with context');
      
      // Include navigation context in the prompt if available
      final promptText = navigationContext != null
          ? '''
Analyze this frame for a blind person navigating to ${navigationContext.destinationName}. 
Navigation Context: 
Current location: ${navigationContext.latitude}, ${navigationContext.longitude}. 
Destination: ${navigationContext.destinationName} (${navigationContext.destinationLatitude}, 
${navigationContext.destinationLongitude}). 
Distance remaining: ${navigationContext.distanceToDestination}m. 
Next direction: ${navigationContext.nextDirection}.
Identify obstacles, path conditions, streets, and nearby landmarks. 
Describe colors and details of important objects in your path. 
Mention if you see street signs, traffic signals, or crosswalks. 
Focus on elements relevant to safe navigation. 
Keep your response under 3 sentences and optimized for text-to-speech.
'''
          : '''
Analyze this frame and describe the environment in detail for a blind person. 
Identify obstacles, path conditions, streets, and nearby landmarks. 
Provide specific colors and locations of objects. 
Mention if you see street signs, traffic signals, or crosswalks. 
Keep your response under 3 sentences and optimized for text-to-speech.
''';
      
      return await _generateContent(imageBytes, promptText);
    } catch (e) {
      debugPrint('Error processing navigation frame: $e');
      return 'Error analyzing surroundings: $e';
    }
  }
  
  // Process text reading
  Future<String> processTextReading(List<int> imageBytes) async {
    try {
      return await _generateContent(
        imageBytes,
        'Read the text from this image and provide the content.',
      );
    } catch (e) {
      debugPrint('Error processing text reading: $e');
      return 'Error reading text: $e';
    }
  }
  
  // Process assistant query
  Future<String> processAssistantQuery(String message, {String? frameData}) async {
    try {
      final fullMessage = frameData != null
          ? 'Frame data: $frameData\n\nUser message: $message'
          : message;
      
      return await _generateContent(
        null,
        fullMessage,
      );
    } catch (e) {
      debugPrint('Error processing assistant query: $e');
      return 'Error processing query: $e';
    }
  }
  
  // Generate content with image and text
  Future<String> _generateContent(List<int>? imageBytes, String promptText) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey');
      
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              if (imageBytes != null)
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Encode(imageBytes),
                  }
                },
              {
                'text': promptText,
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'topK': topK,
          'topP': topP,
          'maxOutputTokens': maxOutputTokens,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_NONE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_NONE',
          },
        ],
      };
      
      if (systemInstruction.isNotEmpty) {
        requestBody['systemInstruction'] = {
          'parts': [
            {
              'text': systemInstruction,
            }
          ]
        };
      }
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? 'No response';
      } else {
        throw Exception('Failed to generate content: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error generating content: $e');
      return 'Error generating content: $e';
    }
  }
}

// Data class for navigation context
class NavigationContext {
  final double latitude;
  final double longitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String destinationName;
  final double distanceToDestination;
  final String nextDirection;
  
  NavigationContext({
    required this.latitude,
    required this.longitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.destinationName,
    required this.distanceToDestination,
    required this.nextDirection,
  });
} 