module Timeline.Update where

import Dict exposing (insert)
import Drag exposing (..)


import Item.Model as Item exposing (Item)
import Timeline.Model exposing (initialModel, Model)

type Action
  = AddItem Item
  | ToggleItemSelection Int Item Bool
  | Track (Maybe Drag.Action)


-- Whether the mouse is hovering over the start time. I think it makes
-- sense to *define* this locally, where it's needed, and then let
-- parent modules pick it up and thread it through the Elm architecture.
-- It's easier for parent modules to "reach down" than for child modules
-- to "reach up". (Well, I guess the "reach up" alternative is for the parent
-- module to provide parameters to functions in the child module (like we do
-- with `view` and addresses), but that seems awkward in this case).
--
-- Note that we'd have to do something a little different if you wanted
-- to be able to have *multiple* draggable triangles on the page at the
-- same time ... then we'd have to use the `trackMany` and index the
-- mailbox type.
startTimeHover : Signal.Mailbox Bool
startTimeHover =
    Signal.mailbox False


-- Actions generated by the drag library. They are defined here, picked up by
-- parent modules, and threaded back to us with the `Track` tag.
--
-- Note that we pre-map the actions that the drag library generates to
-- our own action tag. In a way, this is all exactly the reverse of the
-- usual Elm architecture (where reverse means something nicer than
-- opposite). I suppose the difference is that the drag library demands
-- access to a Signal. I suppoe we could instead thread the Signal down
-- via addresses, like we do with view ...
startTimeActions : Signal Action
startTimeActions =
    Signal.map Track <|
        track False startTimeHover.signal


update : Action -> Model -> Model
update action model =
  case action of
    -- @todo: Convert to Dict.
    AddItem item ->
      let
        items' = Dict.insert model.counter item model.items
      in
        { model
        | items = items'
        , counter = model.counter + 1
        }

    ToggleItemSelection index item val ->
      -- Dict.insert replaces the existing record.
      let
        item' = { item | selected = val }
        items' = Dict.insert index item' model.items
      in
        { model | items = items' }

    Track (Just Lift) ->
      model

    Track (Just (MoveBy (dx, dy))) ->
      { model | startTimePicker = moveBy model.startTimePicker dx }

    Track (Just Release) ->
      model

    Track _ ->
      model


moveBy : Float -> Int -> Float
moveBy x dx =
    let
      val = x + toFloat dx
    in
      if val < -400
        then -400
      else if val > 400
        then 400
      else val
