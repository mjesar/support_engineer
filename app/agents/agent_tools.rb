# The tools the loop may use. The wrapper classes stay the only place that describes a tool;
# this class turns them into what Groq expects and runs them by name.
class AgentTools
  def initialize(tool_classes)
    @tools = tool_classes.map(&:new).index_by(&:name)
  end

  def definitions
    @tools.values.map { |tool| definition(tool) }
  end

  # Unknown names come back as an error hash so the model can see its mistake and recover.
  def run(name, arguments)
    tool = @tools[name]
    return { error: "Unknown tool #{name}" } unless tool

    tool.execute(**arguments.symbolize_keys)
  end

  private

  # "strict" is dropped: RubyLLM sets it at a different level in its own requests.
  def definition(tool)
    { type: "function",
      function: { name: tool.name, description: tool.description,
                  parameters: tool.parameters_schema.except("strict") } }
  end
end
