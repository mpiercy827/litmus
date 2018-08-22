defmodule Litmus.Type.Boolean do
  @moduledoc false

  alias Litmus.Required

  @truthy_default [true, "true"]
  @falsy_default [false, "false"]

  defstruct truthy: @truthy_default,
            falsy: @falsy_default,
            required: false

  @type t :: %__MODULE__{
          truthy: [term],
          falsy: [term],
          required: boolean
        }

  @spec validate_field(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  def validate_field(type, field, data) do
    with {:ok, data} <- Required.validate(type, field, data),
         {:ok, data} <- truthy_falsy_validate(type, field, data) do
      {:ok, data}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  @spec check_boolean_values(term, [term], [term]) :: boolean
  defp check_boolean_values(initial_value, additional_values, default_values)
       when is_binary(initial_value) do
    allowed_values =
      additional_values
      |> (&(&1 ++ default_values)).()
      |> Enum.uniq()
      |> Enum.map(fn item ->
        if is_binary(item) do
          String.downcase(item)
        end
      end)

    String.downcase(initial_value) in allowed_values
  end

  defp check_boolean_values(initial_value, additional_values, default_values) do
    initial_value in Enum.uniq(additional_values ++ default_values)
  end

  @spec truthy_falsy_validate(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  defp truthy_falsy_validate(%__MODULE__{falsy: falsy, truthy: truthy}, field, params) do
    cond do
      !Map.has_key?(params, field) ->
        {:ok, params}

      check_boolean_values(params[field], truthy, @truthy_default) ->
        {:ok, Map.replace!(params, field, true)}

      check_boolean_values(params[field], falsy, @falsy_default) ->
        {:ok, Map.replace!(params, field, false)}

      true ->
        {:error, "#{field} must be a boolean"}
    end
  end

  defimpl Litmus.Type do
    alias Litmus.Type

    @spec validate(Type.t(), String.t(), map) :: {:ok, map} | {:error, String.t()}
    def validate(type, field, data), do: Type.Boolean.validate_field(type, field, data)
  end
end