(*
   Utilities for working with the types defined in Semgrep_core_response.atd
   (Semgrep_core_response_t module)
*)

open Semgrep_core_response_t

let compare_position (a : position) b = Int.compare a.offset b.offset

let compare_location (a : location) b =
  let c = String.compare a.path a.path in
  if c <> 0 then c
  else
    let c = compare_position a.start b.start in
    if c <> 0 then c else compare_position a.end_ b.end_

let compare_metavar_value (a : metavar_value) (b : metavar_value) =
  let c = compare_position a.start b.start in
  if c <> 0 then c else compare_position a.end_ b.end_

(* Generic list comparison. The input lists must already be sorted according
   to 'compare_elt'.

   [1] < [2]
   [1] < [1; 2]
   [1; 2] < [2]
*)
let rec compare_sorted_list compare_elt a b =
  match (a, b) with
  | [], [] -> 0
  | [], _ :: _ -> -1
  | _ :: _, [] -> 1
  | a :: aa, b :: bb ->
      let c = compare_elt a b in
      if c <> 0 then c else compare_sorted_list compare_elt aa bb

(*
   Order the metavariable bindings by location first, then by name.
   (could go the other way too; feel free to change)
*)
let compare_metavar_binding (name1, mv1) (name2, mv2) =
  let c = compare_metavar_value mv1 mv2 in
  if c <> 0 then c else String.compare name1 name2

(* Assumes the metavariable captures within each match_extra are already
   sorted. *)
let compare_match_extra (a : match_extra) (b : match_extra) =
  let c = compare_sorted_list compare_metavar_binding a.metavars b.metavars in
  if c <> 0 then c else compare a.message b.message

(*
   While the locations of the matches are already in correct order, they
   come in a reverse order when looking at the metavariables that they
   match. This function makes a best a effort to return the results
   in a natural order.
*)
let compare_match (a : match_) (b : match_) =
  let c = compare_location a.location b.location in
  if c <> 0 then c else compare_match_extra a.extra b.extra

let sort_metavars (metavars : (string * metavar_value) list) =
  List.stable_sort compare_metavar_binding metavars

let sort_extra (extra : match_extra) =
  { extra with metavars = sort_metavars extra.metavars }

let sort_match_list (matches : match_ list) : match_ list =
  let matches =
    Common.map (fun x -> { x with extra = sort_extra x.extra }) matches
  in
  List.stable_sort compare_match matches

let sort_match_results (res : match_results) : match_results =
  { res with matches = sort_match_list res.matches }
