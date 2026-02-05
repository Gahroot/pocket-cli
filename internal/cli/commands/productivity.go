package commands

import (
	"github.com/spf13/cobra"
	"github.com/unstablemind/pocket/internal/productivity/calendar"
	"github.com/unstablemind/pocket/internal/productivity/notion"
	"github.com/unstablemind/pocket/internal/productivity/todoist"
	"github.com/unstablemind/pocket/internal/productivity/trello"
)

func NewProductivityCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:     "productivity",
		Aliases: []string{"p", "prod"},
		Short:   "Productivity tool commands",
		Long:    `Interact with productivity tools: Calendar, Notion, Todoist, Trello, etc.`,
	}

	cmd.AddCommand(calendar.NewCmd())
	cmd.AddCommand(notion.NewCmd())
	cmd.AddCommand(todoist.NewCmd())
	cmd.AddCommand(trello.NewCmd())

	return cmd
}
