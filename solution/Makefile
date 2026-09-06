NAME        = sorter
NAME2       = depthvis
CC          = gcc
CFLAGS      = -Wall -Wextra -Werror -std=c99 -D_REENTRANT
BUILD       = -g -O0
RELEASE     = -O2
LDFLAGS     = $(shell sdl2-config --libs) -lm

SRCS        = main.c sorts.c bench.c
OBJS        = $(SRCS:.c=.o)

DEPTHVIS_SRCS = depthvis.c
DEPTHVIS_OBJS = $(DEPTHVIS_SRCS:.c=.o)

.PHONY: all release clean fclean re

all: $(NAME) $(NAME2)

$(NAME): $(OBJS)
	$(CC) $(BUILD) $(OBJS) -L. -ltciutil -ltci -o $(NAME)

$(NAME2): $(DEPTHVIS_OBJS)
	$(CC) $(DEPTHVIS_OBJS) -L. -ltci $(LDFLAGS) -o $(NAME2)

%.o: %.c
	$(CC) $(CFLAGS) $(BUILD) -c $< -o $@

release:
	@$(MAKE) --no-print-directory fclean
	@$(MAKE) --no-print-directory BUILD="$(RELEASE)"
	strip $(NAME)

clean:
	rm -f $(OBJS) $(DEPTHVIS_OBJS)

fclean: clean
	rm -f $(NAME) $(NAME2)

re: fclean all
