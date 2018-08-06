defmodule Litmus.Type.List do
  @moduledoc false

  alias Litmus.Required
  alias Litmus.Type

  defstruct [
    :min_length,
    :max_length,
    :length,
    :type,
    required: false
  ]

  @type t :: %__MODULE__{
          min_length: non_neg_integer | nil,
          max_length: non_neg_integer | nil,
          length: non_neg_integer | nil,
          type: String.t() | atom | nil,
          required: boolean
        }

  @spec validate_field(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  def validate_field(type, field, data) do
    with {:ok, data} <- Required.validate(type, field, data),
         {:ok, data} <- validate_list(type, field, data),
         {:ok, data} <- type_validate(type, field, data),
         {:ok, data} <- min_length_validate(type, field, data),
         {:ok, data} <- max_length_validate(type, field, data),
         {:ok, data} <- length_validate(type, field, data) do
      {:ok, data}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  @spec validate_list(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  defp validate_list(%__MODULE__{}, field, params) do
    cond do
      !Map.has_key?(params, field) ->
        {:ok, params}

      is_list(params[field]) ->
        {:ok, params}

      true ->
        {:error, "#{field} must be a list"}
    end
  end

  @spec min_length_validate(t, String.t(), map) :: {:ok, map} | {:error, String.t()}
  defp min_length_validate(%__MODULE__{min_length: nil}, _field, params) do
    {:ok, params}
  end

  defp min_length_validate(%__MODULE__{min_length: min_length}, field, params)
       when is_integer(min_length) and min_length >= 0 do
    if Map.has_key?(params, field) && length(params[field]) < min_length do
      {:error, "#{field} must not be below length of #{min_length}"}
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
    if Map.has_key?(params, field) && length(params[field]) > max_length do
      {:error, "#{field} must not exceed length of #{max_length}"}
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
    if Map.has_key?(params, field) && length(params[field]) != length do
      {:error, "#{field} length must be of #{length} length"}
    else
      {:ok, params}
    end
  end

  @spec type_validate(t, String.t() | atom, map) :: {:ok, map} | {:error, String.t()}
  defp type_validate(%__MODULE__{type: nil}, _field, params) do
    {:ok, params}
  end

  defp type_validate(%__MODULE__{type: type}, field, params) do
    case type do
      :atom -> validate_atom(params, field)
      :boolean -> validate_boolean(params, field)
      :number -> validate_number(params, field)
      :string -> validate_string(params, field)
    end
  end

  @spec validate_atom(map, String.t()) :: {:ok, map} | {:error, String.t()}
  defp validate_atom(params, field) do
    if Enum.all?(params[field], &is_atom/1) do
      {:ok, params}
    else
      {:error, "#{field} must be a list of atoms"}
    end
  end

  @spec validate_boolean(map, String.t()) :: {:ok, map} | {:error, String.t()}
  defp validate_boolean(params, field) do
    if Enum.all?(params[field], &is_boolean/1) do
      {:ok, params}
    else
      {:error, "#{field} must be a list of boolean"}
    end
  end

  @spec validate_number(map, String.t()) :: {:ok, map} | {:error, String.t()}
  defp validate_number(params, field) do
    if Enum.all?(params[field], &is_number/1) do
      {:ok, params}
    else
      {:error, "#{field} must be a list of numbers"}
    end
  end

  @spec validate_string(map, String.t()) :: {:ok, map} | {:error, String.t()}
  defp validate_string(params, field) do
    if Enum.all?(params[field], &is_binary/1) do
      {:ok, params}
    else
      {:error, "#{field} must be a list of strings"}
    end
  end

  defimpl Litmus.Type do
    alias Litmus.Type

    @spec validate(Type.t(), String.t(), map) :: {:ok, map} | {:error, String.t()}
    def validate(type, field, data), do: Type.List.validate_field(type, field, data)
  end
end
