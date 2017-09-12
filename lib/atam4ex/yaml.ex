defmodule ATAM4Ex.YAML do
  @moduledoc "Environment config YAML parsing."

  @doc "Read and post-process YAML file."
  def read!(path) do
    path
    |> YamlElixir.read_from_file()
    |> walk()
  end

  @doc ~S"""
  Post-process YAML generated by YamlElixir/yamerl:

  * Turns string keys into atom keys.
  * Turns pattern %{":env" => "ENV_VAR"} into value of `System.get_env("ENV_VAR")`, raising
  if `nil` or empty.

  ```
  iex> import YamlElixir.Sigil
  iex> yaml = ~y\"\"\"
  a: 1
  b:
    c:
    - "hello"
    - "goodbye"
    d:
      :env: "XXXX"
  \"\"\"
  iex> System.put_env("XXXX", "yyyy")
  iex> ATAM4Ex.YAML.walk(yaml)
  %{a: 1, b: %{c: ["hello", "goodbye"]}, d: "yyyy"}
  ```
  """
  @spec walk(data) :: map when data: map
  @spec walk(data) :: list when data: list
  @spec walk(data) :: String.t when data: String.t
  @spec walk(data) :: number when data: number
  def walk(data)

  def walk(data) when is_map(data) do
    Map.new(data, fn
      {k, %{":env" => "" <> v}} -> {key(k), env!(v)}
      {k, v} -> {key(k), walk(v)}
    end)
  end

  def walk(data) when is_list(data) do
    Enum.map(data, &walk/1)
  end

  def walk(other), do: other

  def key(key) when is_atom(key), do: key
  def key("" <> key), do: String.to_atom(key)

  def env!(name) do
    case System.get_env(name) do
      nil -> raise ArgumentError, "ENV var #{name} is missing"
      "" -> raise ArgumentError, "ENV var #{name} is empty string"
      val -> val
    end
  end
end