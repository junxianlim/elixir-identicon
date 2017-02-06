defmodule Identicon do
  @moduledoc """
    A module for creating Identicons.
  """

  @doc """

    - Creates a new identicon png image from the given string

    ## Example

          iex> Identicon.main("hipster")
          :ok
          iex> File.exists?("hipster.png")
          true
          iex> File.rm("hipster.png")
          :ok
  """

  def main(input) do
    input
    |> hash_input
    |> pick_color
    |> build_grid
    |> filter_odd_squares
    |> build_pixel_map
    |> draw_image
    |> save_image(input)
  end

  @doc """

    - Hashes the input using md5
    - Converts md5 binary to a list and assigns it to hex inside the Identicon.Image struct

    ## Example

          iex> result = Identicon.hash_input("asdf")
          iex> result.hex
          [145, 46, 200, 3, 178, 206, 73, 228, 165, 65, 6, 141, 73, 90, 181, 112]

  """
  def hash_input(input) do
    hex = :crypto.hash(:md5, input)
    |> :binary.bin_to_list

    %Identicon.Image{hex: hex}
  end

  @doc """

    - Fetches the first 3 values in the hex list and uses it as the value of RGB

    ## Example

          iex> result = Identicon.hash_input("asdf")
          iex> result = Identicon.pick_color(result)
          iex> result.color
          {145, 46, 200}

  """
  def pick_color(%Identicon.Image{hex: [r, g, b | _tail]} = image) do
    %Identicon.Image{image | color: { r, g, b }}
  end


  @doc """

    - Builds a grid using the md5 list

    ## Example

            iex> input = "asdf"
            iex> result = input |> Identicon.hash_input |> Identicon.pick_color |> Identicon.build_grid
            iex> result.grid
            [{145, 0}, {46, 1}, {200, 2}, {46, 3}, {145, 4}, {3, 5}, {178, 6}, {206, 7},
             {178, 8}, {3, 9}, {73, 10}, {228, 11}, {165, 12}, {228, 13}, {73, 14},
             {65, 15}, {6, 16}, {141, 17}, {6, 18}, {65, 19}, {73, 20}, {90, 21}, {181, 22},
             {90, 23}, {73, 24}]
  """
  def build_grid(%Identicon.Image{hex: hex} = image) do
    grid =
      hex
      |> Enum.chunk(3)
      |> Enum.map(&mirror_row/1)
      |> List.flatten
      |> Enum.with_index

    %Identicon.Image{image | grid: grid}
  end

  @doc """

    - Takes a list creates a palindrome

    ## Example

          iex> array = [1,2,3]
          iex> result = Identicon.mirror_row(array)
          iex> result
          [1,2,3,2,1]

  """
  def mirror_row(row) do
    [ first, second | _tail ] = row
    row ++ [ second, first]
  end

  @doc """

    - Filters the odd squares of a grid

    ## Example

          iex> input = "asdf"
          iex> result = input |> Identicon.hash_input |> Identicon.pick_color |> Identicon.build_grid
          iex> result.grid
          [{145, 0}, {46, 1}, {200, 2}, {46, 3}, {145, 4}, {3, 5}, {178, 6}, {206, 7},
           {178, 8}, {3, 9}, {73, 10}, {228, 11}, {165, 12}, {228, 13}, {73, 14},
           {65, 15}, {6, 16}, {141, 17}, {6, 18}, {65, 19}, {73, 20}, {90, 21}, {181, 22},
           {90, 23}, {73, 24}]
          iex> result = Identicon.filter_odd_squares(result)
          iex> result.grid
          [{46, 1}, {200, 2}, {46, 3}, {178, 6}, {206, 7}, {178, 8}, {228, 11}, {228, 13},
           {6, 16}, {6, 18}, {90, 21}, {90, 23}]
  """
  def filter_odd_squares(%Identicon.Image{grid: grid} = image) do
    grid = Enum.filter grid, fn({code, _index}) ->
      rem(code, 2) == 0
    end

    %Identicon.Image{image | grid: grid}
  end

  @doc """

    - Builds a pixel map that has the top left and bottom right value for rendering

    ## Example

            iex> input = "asdf"
            iex> result = input |> Identicon.hash_input |> Identicon.pick_color |> Identicon.build_grid |> Identicon.filter_odd_squares |> Identicon.build_pixel_map
            iex> result.pixel_map
            [{{50, 0}, {100, 50}}, {{100, 0}, {150, 50}}, {{150, 0}, {200, 50}},
             {{50, 50}, {100, 100}}, {{100, 50}, {150, 100}}, {{150, 50}, {200, 100}},
             {{50, 100}, {100, 150}}, {{150, 100}, {200, 150}}, {{50, 150}, {100, 200}},
             {{150, 150}, {200, 200}}, {{50, 200}, {100, 250}}, {{150, 200}, {200, 250}}]
  """
  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map = Enum.map grid, fn({_code, index}) ->
      horizontal_distance = rem(index, 5) * 50
      vertical_distance = div(index, 5) * 50
      top_left = {horizontal_distance, vertical_distance}
      bottom_rigiht = {horizontal_distance + 50, vertical_distance + 50}

      {top_left, bottom_rigiht}
    end

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  @doc """

    - Uses the erlang graphical drawer library to render an image
  """
  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each pixel_map, fn({start, stop}) ->
      :egd.filledRectangle(image, start, stop, fill)
    end

    :egd.render(image)
  end

  @doc """
    - Saves image to a file in png format

    ## Example

          iex> input = "asdf"
          iex> image = input |> Identicon.hash_input |> Identicon.pick_color |> Identicon.build_grid |> Identicon.filter_odd_squares |> Identicon.build_pixel_map |> Identicon.draw_image
          iex> Identicon.save_image(image, "new_image")
          iex> File.exists?("new_image.png")
          true
          iex> File.rm("new_image.png")
          :ok

  """
  def save_image(image, input)  do
    File.write("#{input}.png", image)
  end
end
