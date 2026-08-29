extends Node

# Shared state and the signals the scenes talk to each other through.

## Rung by the bell. People starts walking, game.gd watches the quota.
signal next_customer_requested
## Emitted by People once they reach the counter. The document answers this.
signal customer_arrived
## Emitted by the document once it has been stamped and handed back.
signal document_processed
## Emitted by the Next button when the day's quota is done.
signal next_day_requested
## Emitted the first time a sheet is stamped. Watched by the tutorial.
signal document_stamped
## Emitted when the rulebook is flipped to another page. Watched by the tutorial.
signal rulebook_page_turned

var current_day: int = 1

## The species of the applicant currently at the counter. People picks it when
## they are summoned - before the walk, so the sprite that arrives and the card
## that follows are the same creature - and the document reads it from here.
var current_race: String = ""

## Set once the tutorial is finished or skipped, so it does not come back for
## the rest of the run.
var tutorial_done: bool = false

## Every document handed back today, appended by document.gd and read by
## game.gd for the served count and by the end-of-day screen for the table.
var daily_documents: Array[Dictionary] = []


func advance_day() -> void:
	current_day += 1
	# Must clear, or day 2 starts already at day 1's count and the game
	# thinks the quota is met before a single customer walks in.
	daily_documents.clear()
