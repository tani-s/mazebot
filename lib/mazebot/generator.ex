defmodule Mazebot.Generator do
  @moduledoc """
  Generates a maze using Eller's algorithm.
  Big thanks to https://weblog.jamisbuck.org/2010/12/29/maze-generation-eller-s-algorithm
  """

  def generate_maze(size) do
    initial_state = size |> init() |> random_join(1)

    %{edges: edges} =
      Enum.reduce(1..(size - 1), initial_state, fn step_index, acc_state ->
        acc_state
        |> fill_next_row(step_index, size)
        |> random_join(step_index + 1)
      end)

    edges
  end

  defp init(size) do
    sets = Map.new(1..size, fn set -> {set, [{1, set}]} end)

    cells = %{1 => Map.new(1..size, fn col -> {col, col} end)}

    edges = []

    %{sets: sets, cells: cells, edges: edges, size: size}
  end

  defp random_join(%{cells: cells, size: size} = state, row_index) when row_index < size do
    row = Map.get(cells, row_index)
    # don't join cells if their set is the same
    Enum.reduce(row, state, fn {cell, set}, %{cells: acc_cells} = acc_state ->
      updated_row = Map.get(acc_cells, row_index)

      if Map.get(updated_row, cell + 1) == set or :rand.uniform(2) == 1 or cell == size do
        acc_state
      else
        merge(acc_state, {row_index, cell}, {row_index, cell + 1})
      end
    end)
  end

  # on the last row, connect adjacent cells if they are not in the same set
  defp random_join(%{cells: cells, size: size} = state, row_index) when row_index == size do
    row = Map.get(cells, row_index)

    Enum.reduce(row, state, fn {cell, set}, acc_state ->
      if Map.get(row, cell + 1) == set or cell == size do
        acc_state
      else
        merge(acc_state, {row_index, cell}, {row_index, cell + 1})
      end
    end)
  end

  defp merge(%{sets: sets, cells: cells, edges: edges, size: size}, {x1, y1}, {x2, y2}) do
    sink = get_in(cells, [x1, y1])
    target = get_in(cells, [x2, y2])

    # update the cells map, setting target cells to sink cells
    new_cells =
      Enum.reduce(Map.get(sets, target), cells, fn {x, y}, acc ->
        %{acc | x => %{Map.get(acc, x) | y => sink}}
      end)

    # add the target cells to the sink set and remove the target set
    new_sets =
      sets
      |> Map.put(sink, Enum.concat(Map.get(sets, sink), Map.get(sets, target)))
      |> Map.put(target, [])

    %{
      sets: new_sets,
      cells: new_cells,
      edges: [{size * (x1 - 1) + y1, size * (x2 - 1) + y2} | edges],
      size: size
    }
  end

  # Create vertical corridors, then fill remaining cells in the new row with new sets
  defp fill_next_row(%{sets: sets, cells: cells, edges: edges, size: size}, row_index, size) do
    row = Map.get(cells, row_index)
    row_sets = Enum.group_by(Map.keys(row), &Map.get(row, &1))

    selected_indices =
      Enum.reduce(row_sets, [], fn {_set, cells}, acc ->
        # take at least one (up to all) cells in the set at random
        random_cells = Enum.take_random(cells, :rand.uniform(Enum.count(cells)))
        Enum.concat(acc, random_cells)
      end)

    new_edges =
      Enum.map(selected_indices, fn i -> {size * (row_index - 1) + i, size * row_index + i} end)

    new_row =
      Enum.reduce(1..size, %{}, fn cell, acc ->
        if cell in selected_indices do
          Map.put(acc, cell, get_in(cells, [row_index, cell]))
        else
          # new set numbers are just the number of the cell in the grid
          Map.put(acc, cell, size * row_index + cell)
        end
      end)

    new_sets =
      Enum.reduce(new_row, sets, fn {cell, set}, acc_set ->
        Map.put(acc_set, set, [{row_index + 1, cell} | Map.get(acc_set, set, [])])
      end)

    %{
      sets: new_sets,
      cells: Map.put(cells, row_index + 1, new_row),
      edges: Enum.concat(new_edges, edges),
      size: size
    }
  end
end
