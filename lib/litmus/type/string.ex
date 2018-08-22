defmodule Litmus.Type.String do
  @moduledoc false

  alias Litmus.Required
  alias Litmus.Type

  defstruct [
    :min_length,
    :max_length,
    :length,
    regex: %Type.String.Regex{},
    trim: false,
    required: false
  ]

  @type t :: %__MODULE__{
          min_length: non_neg_integer | nil,
          max_length: non_neg_integer | nil,
          length: non_neg_integer | nil,
          regex: Type.String.Regex.t(),
          trim: boolean,
          required: boolean
        }

  @spec validate_field(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  def validate_field(type, field, data) do
    with {:ok, data} <- Required.validate(type, field, data),
         {:ok, data} <- convert(type, field, data),
         {:ok, data} <- trim(type, field, data),
         {:ok, data} <- min_length_validate(type, field, data),
         {:ok, data} <- max_length_validate(type, field, data),
         {:ok, data} <- length_validate(type, field, data),
         {:ok, data} <- regex_validate(type, field, data) do
      {:ok, data}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  @spec convert(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  defp convert(%__MODULE__{}, field, params) do
    cond do
      !Map.has_key?(params, field) ->
        {:ok, params}

      is_nil(params[field]) ->
        {:ok, Map.put(params, field, "")}

      is_binary(params[field]) ->
        {:ok, params}

      is_number(params[field]) or is_boolean(params[field]) ->
        {:ok, Map.update!(params, field, &to_string/1)}

      true ->
        {:error, "#{field} must be a string"}
    end
  end

  @spec min_length_validate(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  defp min_length_validate(%__MODULE__{min_length: nil}, _field, params) do
    {:ok, params}
  end

  defp min_length_validate(%__MODULE__{min_length: min_length}, field, params)
       when is_integer(min_length) and min_length >= 0 do
    if Map.has_key?(params, field) && String.length(params[field]) < min_length do
      {:error, "#{field} length must be greater than or equal to #{min_length} characters"}
    else
      {:ok, params}
    end
  end

  @spec max_length_validate(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  defp max_length_validate(%__MODULE__{max_length: nil}, _field, params) do
    {:ok, params}
  end

  defp max_length_validate(%__MODULE__{max_length: max_length}, field, params)
       when is_integer(max_length) and max_length >= 0 do
    if Map.has_key?(params, field) && String.length(params[field]) > max_length do
      {:error, "#{field} length must be less than or equal to #{max_length} characters"}
    else
      {:ok, params}
    end
  end

  @spec length_validate(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  defp length_validate(%__MODULE__{length: nil}, _field, params) do
    {:ok, params}
  end

  defp length_validate(%__MODULE__{length: length}, field, params)
       when is_integer(length) and length >= 0 do
    if Map.has_key?(params, field) && String.length(params[field]) != length do
      {:error, "#{field} length must be #{length} characters"}
    else
      {:ok, params}
    end
  end

  @spec regex_validate(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  defp regex_validate(%__MODULE__{regex: %{pattern: nil}}, _field, params) do
    {:ok, params}
  end

  defp regex_validate(%__MODULE__{regex: regex}, field, params) do
    if Map.has_key?(params, field) and !Regex.match?(regex.pattern, params[field]) do
      error_message = regex.error_message || "#{field} must be in a valid format"
      {:error, error_message}
    else
      {:ok, params}
    end
  end

  @spec trim(t, String.t(), map) :: {:ok, map}
  defp trim(%__MODULE__{trim: true}, field, params) do
    if Map.has_key?(params, field) do
      trimmed_value = String.trim(params[field])
      trimmed_params = Map.put(params, field, trimmed_value)
      {:ok, trimmed_params}
    else
      {:ok, params}
    end
  end

  defp trim(%__MODULE__{trim: false}, _field, params) do
    {:ok, params}
  end

  defimpl Litmus.Type do
    alias Litmus.Type

    @spec validate(Type.t(), String.t(), map) :: {:ok, map} | {:error, String.t()}
    def validate(type, field, data), do: Type.String.validate_field(type, field, data)
  end
end