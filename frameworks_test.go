package main

import (
	"path/filepath"
	"testing"

	"github.com/kudobuilder/kudo/pkg/test"
)

// Launch the KUDO tests.
func TestKudoFrameworks(t *testing.T) {
	matches, err := filepath.Glob("./repository/*/tests")
	if err != nil {
		t.Fatal(err)
	}

	harness := test.Harness{
		T:         t,
		TestDirs:  matches,
		StartKUDO: true,
	}

	harness.Run()
}
