# adapted from the example at https://makefiletutorial.com/

SHELL := /bin/bash

TARGET_EXEC := bitsort
TARGET_TEST := run_tests

BUILD_DIR := ./build
SRC_DIRS := ./src
TEST_DIRS := ./tests

MAIN_FILE_NAME := main.c

CC := gcc
CXX := g++

# Find all the C and C++ files we want to compile
# Note the single quotes around the * expressions. The shell will incorrectly expand these otherwise, but we want to send the * directly to the find command.
SRCS := $(shell find $(SRC_DIRS) -name '*.cpp' -or -name '*.c')

TEST_SRCS := $(shell find $(TEST_DIRS) -name '*.cpp' -or -name '*.c')
TEST_SRCS += $(filter-out $(SRC_DIRS)/$(MAIN_FILE_NAME), $(SRCS))

# Prepends BUILD_DIR and appends .o to every src file
# As an example, ./src/hello.cpp turns into ./build/./src/hello.cpp.o
OBJS := $(SRCS:%=$(BUILD_DIR)/%.o)
TEST_OBJS := $(TEST_SRCS:%=$(BUILD_DIR)/%.o)

# String substitution (suffix version without %).
# As an example, ./build/hello.cpp.o turns into ./build/hello.cpp.d
DEPS := $(OBJS:.o=.d)
TEST_DEPS := $(TEST_OBJS:.o=.d)

# Every folder in ./src will need to be passed to GCC so that it can find header files
INC_DIRS := $(shell find $(SRC_DIRS) -type d)
# Add a prefix to INC_DIRS. So moduleA would become -ImoduleA. GCC understands this -I flag
INC_FLAGS := $(addprefix -I,$(INC_DIRS))

# The -MMD and -MP flags together generate Makefiles for us!
# These files will have .d instead of .o as the output.
CPPFLAGS := $(INC_FLAGS) -Wall -MMD -MP

# The final build step.
$(BUILD_DIR)/$(TARGET_EXEC): $(OBJS)
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)

# Build step for C source
$(BUILD_DIR)/%.c.o: %.c
	mkdir -p $(dir $@)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# Build step for C++ source
$(BUILD_DIR)/%.cpp.o: %.cpp
	mkdir -p $(dir $@)
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@


.PHONY: test
test: $(TEST_OBJS)
	$(CXX) $(TEST_OBJS) -o $(BUILD_DIR)/$(TARGET_TEST) $(LDFLAGS)
	$(BUILD_DIR)/$(TARGET_TEST)


.PHONY: clean
clean:
	rm -r $(BUILD_DIR)

# Include the .d makefiles. The - at the front suppresses the errors of missing
# Makefiles. Initially, all the .d files will be missing, and we don't want those
# errors to show up.
-include $(DEPS)
-include $(TEST_DEPS)
