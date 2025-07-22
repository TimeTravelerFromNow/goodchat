class ReviewCommentJob < ApplicationJob
  MARK_COMMENT_STATUS_TOOL = {
    "name": "mark_comment_status",
    "description": "Mark the comment's status as public with a specified value after evaluation.",
    "strict": true,
    "type": "function",
    "parameters": {
      "type": "object",
      "properties": {
        "status": {
          "type": "string",
          "description": "The status to assign to the comment after evaluation.",
          "enum": [
            "good",
            "hateful",
            "spam",
            "undetermined"
          ]
        }
      },
      "required": [
        "status"
      ],
      "additionalProperties": false
    }
  }

  INSTRUCTIONS = "Review the comment content. Your job is to determine if a comment can be publicized; then mark it 'good' status" +
    "if the comment is hateful (divisive or directing unkind words towards a person or people) mark it 'hateful'" +
    "Mark the comment spam if it is gibberrish, promoting or sellilng products, random text or links to fishy websites/advertising"+
    "If you are uncertain about the good status, mark it 'undetermined'."

  def perform(comment)
    @comment = comment
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.openai.secret_key)

    # review comment with api
    response = create_response

    # function call update's comment status
    handle_function_call(response)

    # optional cleanup
    cleanup_response(response)
  end

  def create_response
    input = "Commenter name and email: #{@comment.name} #{@comment.email}" +
     "Comment content: #{@comment.content}"

    @client.responses.create(
      parameters: {
        model: "gpt-4o-mini",
        input: input,
        instructions: INSTRUCTIONS,
        tools: [ MARK_COMMENT_STATUS_TOOL ],
        tool_choice: "required"
      }
    )
  end

  def handle_function_call(response)
    function_call = response.dig("output", 0)

    function_name = function_call["name"]
    function_args = JSON.parse(function_call["arguments"])

    raise "UNKNOWNFUNCTION::#{function_name}" unless function_name == "mark_comment_status"

    @comment.update(status: function_args["status"])
  end

  def cleanup_response(response)
    deletion = @client.responses.delete(response_id: response["id"])
    raise "DELETION_FAILED::#{deletion.inspect} response: #{response.inspect}" unless deletion["deleted"]
  end
end
